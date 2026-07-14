# Solution: Docker Basics

- `docker run hello-world` → the greeting message confirms the daemon is working.
- `docker run -it --rm python:3 python` → `from datetime import date; print(date.today())` prints today's date;
  end the session with `exit()`.
- Check versions: `docker version` → prints the client/server version (e.g. Docker Desktop/Engine 27.x).
- Daemon info: `docker info`
  - Default runtime: the value after `Runtimes`/`Default Runtime` (usually `runc`).
  - Additional runtimes: the list after `Runtimes`.
  - Host OS/kernel, CPUs and memory are listed under `Operating System`, `CPUs` and `Total Memory`.
