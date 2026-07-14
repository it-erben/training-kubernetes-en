# Lab 08: Simple Server

This project shows how a minimalistic Python HTTP service is packaged as a wheel and used in a Docker
image.

## Project structure

The following files make up the project. Create the directory structure as follows:

```text
08-docker-python-challenge/
├── pyproject.toml
├── .dockerignore
└── src/
    └── simple_server/
        ├── __init__.py
        └── server.py
```

**`pyproject.toml`:**

```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "simple-server-app"
version = "0.1.0"
description = "Simple HTTP server packaged as a wheel"
readme = "README.md"
license = {text = "MIT"}
authors = [
  {name = "GFU Challenges"}
]
requires-python = ">=3.10"
dependencies = []

[project.scripts]
simple-server = "simple_server.server:main"

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]
```

**`.dockerignore`:**

```txt
.venv
__pycache__
.pytest_cache
.mypy_cache
dist
build
.git
.gitignore
.DS_Store
```

**`src/simple_server/__init__.py`:**

```python
"""Simple HTTP server package."""

__all__ = ["server"]
```

**`src/simple_server/server.py`:**

```python
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
```

## Create a Dockerfile for this service

Multi-stage builds separate the build process from the runtime environment: first, dependencies and tools are used in
a builder stage, then only the finished artifacts are moved into a slim runtime stage. This keeps the
final image small and secure.

1. **Choose a base image**  
   Use `python:3.11-slim` for both stages to keep the image compact while still having all the tools needed to build
   the wheel and to run the application.

2. **Define the builder stage**

   ```dockerfile
   FROM python:3.11-slim AS builder
   WORKDIR /app
   ENV PIP_DISABLE_PIP_VERSION_CHECK=1
   ```

   Now copy `pyproject.toml`, `README.md` and the `src` folder to `/app`. Then, in a `RUN` instruction, install the
   `build` tool by running the command `pip install --upgrade pip build`. Afterwards, run
   `python -m build --wheel --no-isolation` so that the wheel is created in `dist/`.

3. **Start the runtime stage**

   ```dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
       PYTHONUNBUFFERED=1
   ```

   Copy `dist/` from the builder stage (remember `COPY --from=builder`), then run `pip install /tmp/dist/*.whl`.
   Afterwards, delete the temporary directory.

4. **Expose the port and set the start command**  
   Add `EXPOSE 8080` and set `CMD ["simple-server"]` so that the container automatically runs the server on
   startup.

Put these steps together in the order given to recreate the current multi-stage Dockerfile.
