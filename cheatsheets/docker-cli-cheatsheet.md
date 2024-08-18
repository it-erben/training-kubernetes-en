# Docker-CLI und Docker-Compose Cheat-Sheet für Einsteiger

## Docker-CLI Befehle

### Grundlegende Befehle

* `docker --version`: Zeigt die installierte Docker-Version an.
* `docker info`: Zeigt Systeminformationen zu Docker an.

### Images

* `docker images`: Listet alle verfügbaren Docker-Images auf.
* `docker pull <image>`: Lädt ein Docker-Image aus der Docker-Registry herunter.
* `docker images rm <image>`: Löscht ein Docker-Image.
* `docker rmi <image>`: Löscht ein Docker-Image (Kurzform).

### Container

* `docker ps`: Listet alle laufenden Docker-Container auf.
* `docker ps -a`: Listet alle Docker-Container auf, auch die gestoppten.
* `docker run <image>`: Erstellt und startet einen neuen Docker-Container aus einem Image.
* `docker start <container>`: Startet einen gestoppten Docker-Container.
* `docker stop <container>`: Stoppt einen laufenden Docker-Container.
* `docker rm <container>`: Löscht einen Docker-Container.
* `docker logs <container>`: Zeigt die Logs eines Docker-Containers an.
* `docker exec -it <container> <command>`: Führt einen Befehl in einem laufenden Docker-Container aus.

### Image Tagging

* `docker pull <image>:<tag>`: Lädt ein Docker-Image mit einem bestimmten Tag aus der Docker-Registry herunter. Wenn kein Tag angegeben ist, wird standardmäßig der Tag `latest` verwendet.
* `docker tag <source_image>:<source_tag> <target_image>:<target_tag>`: Erstellt einen neuen Tag für ein vorhandenes Docker-Image. Wenn kein `source_tag` angegeben ist, wird standardmäßig der Tag `latest` verwendet.
* `docker push <image>:<tag>`: Lädt ein getaggtes Docker-Image in die Docker-Registry hoch. Wenn kein Tag angegeben ist, wird standardmäßig der Tag `latest` verwendet.
* `docker rmi <image>:<tag>`: Löscht ein getaggtes Docker-Image. Wenn kein Tag angegeben ist, wird standardmäßig der Tag `latest` verwendet.

### Docker Compose-Befehle

* `docker compose --version`: Zeigt die installierte Docker-Compose-Version an.
* `docker compose up`: Erstellt und startet alle Services, die in der `docker-compose.yml`-Datei definiert sind.
* `docker compose down`: Stoppt und entfernt alle Services, die in der `docker-compose.yml`-Datei definiert sind.
* `docker compose ps`: Listet alle Services auf, die in der `docker-compose.yml`-Datei definiert sind.
* `docker compose start <service>`: Startet einen bestimmten Service.
* `docker compose stop <service>`: Stoppt einen bestimmten Service.
* `docker compose logs <service>`: Zeigt die Logs eines bestimmten Services an.
* `docker compose exec <service> <command>`: Führt einen Befehl in einem laufenden Service aus.

### Docker Compose-Datei

Die `docker-compose.yml`-Datei ist eine YAML-Datei, die die Services, Netzwerke und Volumes für eine Docker-Anwendung definiert. Hier ist ein einfaches Beispiel:

```yaml
version: '3'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
  db:
    image: postgres:latest
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
```

In diesem Beispiel werden zwei Services definiert: `web` (ein Nginx-Webserver) und `db` (eine PostgreSQL-Datenbank).