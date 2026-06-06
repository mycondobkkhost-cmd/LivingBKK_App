#!/usr/bin/env bash
# บังคับแก้ profiles.role บัญชี demo (แก้แอดมินไม่เด้งหลังบ้าน)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1090
source "$ROOT/.env.local"

URL="${SUPABASE_URL%/}"
KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

python3 <<'PY'
import json, os, urllib.request

url = os.environ["SUPABASE_URL"].rstrip("/")
key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

accounts = [
    ("demo-owner@livingbkk.local", "owner", "Demo Owner"),
    ("demo-admin@livingbkk.local", "admin", "Demo Admin"),
    ("demo-seeker@livingbkk.local", "seeker", "Demo Seeker"),
]

def req(method, path, body=None, prefer=None):
    import urllib.error

    headers = {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }
    if prefer:
        headers["Prefer"] = prefer
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(f"{url}{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r) as res:
            raw = res.read().decode()
            return res.status, (json.loads(raw) if raw else None), None
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        return e.code, None, err

# list users
status, users_payload, err = req("GET", "/auth/v1/admin/users?per_page=200")
users = {u["email"].lower(): u["id"] for u in (users_payload or {}).get("users", [])}

for email, role, name in accounts:
    uid = users.get(email.lower())
    if not uid:
        print(f"❌ ไม่พบ user: {email}")
        continue
    # sync auth metadata (optional)
    _, _, auth_err = req(
        "PUT",
        f"/auth/v1/admin/users/{uid}",
        {"user_metadata": {"role": role, "display_name": name}},
    )
    if auth_err:
        print(f"↷ ข้าม auth metadata {email}: {auth_err[:120]}")
    # upsert profile
    _, rows, prof_err = req(
        "POST",
        "/rest/v1/profiles?on_conflict=id",
        {"id": uid, "role": role, "display_name": name},
        prefer="resolution=merge-duplicates,return=representation",
    )
    if prof_err or not rows or (rows and rows[0].get("role") != role):
        # trigger ห้ามอัปเดตเป็น admin — ลบแล้ว insert ใหม่ (trigger มีแค่ UPDATE)
        req("DELETE", f"/rest/v1/profiles?id=eq.{uid}")
        _, rows, ins_err = req(
            "POST",
            "/rest/v1/profiles",
            {"id": uid, "role": role, "display_name": name},
            prefer="return=representation",
        )
        if ins_err or not rows:
            print(f"❌ profile ไม่สำเร็จ {email}: {(prof_err or ins_err or 'empty')[:200]}")
            print(f"   → รัน SQL ใน Dashboard: scripts/fix-demo-roles.sql")
            continue
    got = rows[0].get("role")
    mark = "✅" if got == role else "⚠️"
    print(f"{mark} {email} → profiles.role = {got}")
PY

echo ""
echo "เสร็จ — ออกจากระบบแล้วล็อกอิน demo-admin ใหม่"
