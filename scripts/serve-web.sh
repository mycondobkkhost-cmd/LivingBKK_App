#!/usr/bin/env bash
# เสิร์ฟ Flutter web build — รองรับ /admin /admin/console (SPA fallback)
set -e
PORT="${1:-8766}"
ROOT="$(dirname "$0")/../mobile/build/web"
cd "$ROOT"
if [[ ! -f index.html ]]; then
  echo "ยังไม่มี build — รัน: cd mobile && flutter build web --release" >&2
  exit 1
fi
echo "PROPPITER web → http://127.0.0.1:${PORT}/"
echo "  Admin:   http://127.0.0.1:${PORT}/admin"
echo "  Console: http://127.0.0.1:${PORT}/admin/console"
exec python3 - "$PORT" <<'PY'
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

PORT = int(sys.argv[1])
ROOT = Path(".").resolve()

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        rel = self.path.split("?", 1)[0]
        target = ROOT / rel.lstrip("/")
        if rel != "/" and not target.is_file():
            self.path = "/index.html"
        return super().do_GET()

    def log_message(self, fmt, *args):
        print(f"[{self.log_date_time_string()}] {fmt % args}")

HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
PY
