"""Minimal HTTP server used inside the Docker image."""

from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Tuple


class RootHandler(BaseHTTPRequestHandler):
    """Serve a JSON greeting on the root path."""

    server_version = "SimpleServer/0.1"

    def do_GET(self) -> None:  # noqa: N802 (method name required by BaseHTTPRequestHandler)
        self._send_json({"message": "Hello from the simple server!"})

    def log_message(self, format: str, *args: object) -> None:  # noqa: A003
        """Route logs through stdout instead of stderr."""
        print(f"{self.address_string()} - - [{self.log_date_time_string()}] {format % args}")

    def _send_json(self, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def run_server(host: str = "0.0.0.0", port: int | None = None) -> Tuple[str, int]:
    """Run the HTTP server and return the address it is bound to."""
    port = port or int(os.getenv("PORT", "8080"))
    with ThreadingHTTPServer((host, port), RootHandler) as httpd:
        print(f"Started server")
        httpd.serve_forever()
    return host, port


def main() -> None:
    """Entry-point used by the console script."""
    run_server()


if __name__ == "__main__":
    main()
