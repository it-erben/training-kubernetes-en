# 📄 Docker-CLI & Compose Cheat-Sheet

## Grundlegendes

- `docker --version` – Zeigt installierte Version
- `docker info` – Systeminfos (Daemon, Runtime, OS, CPU, RAM)

---

## Images

- `docker images` – Listet vorhandene Images
- `docker pull <image>:<tag>` – Image aus Registry laden (default: `latest`)
- `docker image rm <image>:<tag>` – Entfernt ein Image
- `docker inspect <image>` – Details (z. B. `.Os`, `.Created`, `.Config.Env`)
- `docker tag <image>:<tag> <alias>:<tag>` – Alias/Umbenennung eines Images
- `docker push <image>:<tag>` – Image in Registry hochladen

---

## Container

- `docker ps` – Laufende Container
- `docker ps -a` – Alle Container (auch gestoppte)
- `docker run -it --rm <image> <cmd>` – Startet Container interaktiv & löscht ihn beim Beenden
- `docker create --name <name> <image>` – Legt einen neuen Container an, der noch nicht gestartet ist
- `docker start <name>` – Startet gestoppten Container
- `docker stop <name>` – Stoppt laufenden Container
- `docker rm <name>` – Löscht gestoppten Container
- `docker logs <name>` – Zeigt Container-Logs
- `docker exec <name> <cmd>` – Führt einen Befehl im Container aus(z. B. `nano`)
- `docker exec -it <name> <cmd>` – Öffnet eine interaktive Sitzung mit dem Container (z. B. `bash`)

---

## Volumes & Bind Mounts

- `docker volume ls` – Listet Volumes
- `docker run -v <vol>:/path <image>` – Container mit Volume starten
- `docker run -v $(pwd):/tmp/scripts <image>` – Bind-Mount (Host → Container)

---

## Netzwerke

- `docker network ls` – Alle Netzwerke
- `docker network create <name>` – Neues Netzwerk
- `docker run --network <name> --name <container> <image>` – Container mit Netzwerk starten
- `docker exec -it <c1> ping <c2>` – Container über Namen anpingen
