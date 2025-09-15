# Docker Container

## Übung 1

In dieser Übung gehen wir das Erzeugen, Starten, Stoppen und Löschen von Containern durch.
Mache dich mit den Befehlen vertraut und lass dir ruhig etwas Zeit, die jeweiligen Ausgaben der Befehle zu verstehen.

Erzeuge einen Container vom `httpd:latest` Image und nenne es "my-httpd"

```shell
docker pull httpd:latest
docker create --name my-httpd httpd:latest
```

Lass‘ dir den Container mit dem ls-Befehl anzeigen (an das -a Flag denken)
```shell
docker container ls -a 
```
Starte den Container
```shell
docker start my-httpd
``` 
Lass dir den Zustand aller Container anzeichen und suche den my-httpd-Container
```shell
docker ps
```

Stoppe und lösche anschließend den Container

```shell
docker stop my-httpd
docker rm my-httpd
```

## Übung 2
In dieser Übung üben wir nochmal, einen Container zu erzeugen und zu starten.
Anschließend benutzen wird den `exec`-Befehl, um auf einem laufenden Container Änderungen vorzunehmen.
Wir installieren dabei den Texteditor nano und führen ihn danach auf dem Container aus.
--- 
Erzeuge mit `docker create` und `start` einen nginx Container.

```shell
docker create --name praxisaufgabe nginx
docker start praxisaufgabe
```
Führe die Befehle `apt-get update` und `apt-get install nano -y` auf dem Container aus.
```shell
docker exec praxisaufgabe "apt-get" "update"
docker exec praxisaufgabe "apt-get" "install" "nano" "-y"
```
Verbinde dich mit dem Container durch eine Bash-Sitzung und starte `nano`.
```shell
docker exec -it praxisaufgabe bash
nano
```
