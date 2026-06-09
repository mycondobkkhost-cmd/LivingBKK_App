#!/usr/bin/env python3
"""Validate metro PH slugs, บันทึกที่ล้มเหลว แล้ว retry batch import."""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIPELINE = Path(os.environ.get("PH_PIPELINE_DIR", ROOT / "data/ph-pipeline"))
SLUG_FILE = Path(sys.argv[1]) if len(sys.argv) > 1 else PIPELINE / "ph-slugs-metro.json"
FAILED_LIST = PIPELINE / "ph-slugs-failed.json"
RETRY_LOG = PIPELINE / "retry-failed.log"
VALIDATE_CHUNK = int(os.environ.get("VALIDATE_CHUNK", "40"))
BATCH_SIZE = int(os.environ.get("BATCH_SIZE", "20"))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    for path in (ROOT / ".env.local", ROOT / "mobile/assets/env"):
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env.setdefault(k, v)
    return env


def log(msg: str) -> None:
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line)
    with RETRY_LOG.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def http_json(url: str, data: dict | None, headers: dict[str, str]) -> dict:
    body = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(
        url,
        data=body,
        headers=headers,
        method="GET" if data is None else "POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode())


def main() -> int:
    if not SLUG_FILE.exists():
        print(f"❌ ไม่พบ {SLUG_FILE}", file=sys.stderr)
        return 1

    slugs: list[str] = json.loads(SLUG_FILE.read_text()).get("slugs", [])
    if not slugs:
        print("❌ ไม่มี slug")
        return 1

    env = load_env()
    base = env.get("SUPABASE_URL", "https://auflqgqrmpbioflnhsrj.supabase.co")
    anon = env.get("SUPABASE_ANON_KEY", "")
    email = os.environ.get("ADMIN_EMAIL", "demo-admin@livingbkk.local")
    password = os.environ.get("ADMIN_PASSWORD", "demo12345")

    token = http_json(
        f"{base}/auth/v1/token?grant_type=password",
        {"email": email, "password": password},
        {"apikey": anon, "Content-Type": "application/json"},
    ).get("access_token")
    if not token:
        log("❌ ล็อกอินแอดมินไม่สำเร็จ")
        return 1

    headers = {
        "apikey": anon,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    fn_url = f"{base}/functions/v1/project-import-propertyhub"

    log(f"validate {len(slugs)} slugs (chunk={VALIDATE_CHUNK})")
    failed: dict[str, str] = {}

    for offset in range(0, len(slugs), VALIDATE_CHUNK):
        chunk = slugs[offset : offset + VALIDATE_CHUNK]
        try:
            resp = http_json(
                fn_url,
                {"mode": "validate_slugs", "slugs": chunk, "limit": len(chunk)},
                headers,
            )
        except urllib.error.HTTPError as e:
            log(f"❌ validate HTTP {e.code}: {e.read().decode()[:200]}")
            return 1

        for item in resp.get("invalid", []):
            slug = item.get("slug")
            if slug:
                failed[slug] = item.get("error", "unknown")
                log(f"invalid\t{slug}\t{item.get('error')}")

        log(f"validate {min(offset + VALIDATE_CHUNK, len(slugs))}/{len(slugs)} · failed {len(failed)}")
        time.sleep(0.3)

    failed_slugs = sorted(failed)
    FAILED_LIST.write_text(
        json.dumps({"count": len(failed_slugs), "slugs": failed_slugs, "errors": failed}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    log(f"พบล้มเหลว {len(failed_slugs)} slug → {FAILED_LIST}")

    if not failed_slugs:
        log("✅ ไม่มี slug ที่ validate ไม่ผ่าน")
        return 0

    log(f"retry import {len(failed_slugs)} slugs (batch={BATCH_SIZE})")
    ok_total = 0
    fail_total = 0

    for offset in range(0, len(failed_slugs), BATCH_SIZE):
        batch = failed_slugs[offset : offset + BATCH_SIZE]
        try:
            resp = http_json(
                fn_url,
                {
                    "mode": "batch",
                    "slugs": batch,
                    "limit": len(batch),
                    "import_scope": "metro",
                },
                headers,
            )
        except urllib.error.HTTPError as e:
            log(f"❌ batch HTTP {e.code}: {e.read().decode()[:200]}")
            return 1

        if resp.get("error"):
            log(f"❌ batch error: {resp['error']}")
            return 1

        ok = int(resp.get("ok", 0))
        fail = int(resp.get("fail", 0))
        ok_total += ok
        fail_total += fail

        for row in resp.get("results", []):
            if not row.get("ok"):
                log(f"retry_fail\t{row.get('slug')}\t{row.get('error')}")

        log(
            f"retry batch {offset // BATCH_SIZE + 1} · "
            f"{min(offset + BATCH_SIZE, len(failed_slugs))}/{len(failed_slugs)} · "
            f"ok {ok_total} · fail {fail_total}"
        )
        time.sleep(0.5)

    still_failed = [
        row.get("slug")
        for offset in range(0, len(failed_slugs), BATCH_SIZE)
        for row in []  # populated below from last responses - recompute at end
    ]

    # re-validate remaining failures
    log("re-validate failed slugs")
    remaining: dict[str, str] = {}
    for offset in range(0, len(failed_slugs), VALIDATE_CHUNK):
        chunk = failed_slugs[offset : offset + VALIDATE_CHUNK]
        resp = http_json(
            fn_url,
            {"mode": "validate_slugs", "slugs": chunk, "limit": len(chunk)},
            headers,
        )
        for item in resp.get("invalid", []):
            slug = item.get("slug")
            if slug:
                remaining[slug] = item.get("error", "unknown")

    still_path = PIPELINE / "ph-slugs-still-failed.json"
    still_path.write_text(
        json.dumps(
            {"count": len(remaining), "slugs": sorted(remaining), "errors": remaining},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    log(f"✅ retry จบ — สำเร็จ {ok_total} · ล้มเหลว {fail_total} · ยังไม่ผ่าน validate {len(remaining)}")
    log(f"   รายการที่ยังไม่ผ่าน: {still_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
