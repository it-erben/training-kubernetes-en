# Dockerfiles

## Aufgabe 1

In dieser Aufgabe legen wir eine kleine Flask-Anwendung an, verpacken sie in ein Docker-Image und starten einen Container davon.

Baue zuerst das Image mit den in diesem Verzeichnis gegebenen Dateien.
```shell
docker build -t my_flask_app .
```

Starte nun einen Container davon
```shell
docker run -d -p 8080:80 --name my_flask_container my_flask_app
```

Öffne nun einen Browser auf http://localhost:8080 und schau, ob die Anwendung läuft.

Schau dir die Logs an
```shell
docker logs my_flask_container
```
Cleanup:
```shell
docker stop my_flask_container
docker container rm my_flask_container
docker image rm my_flask_app
```

## Aufgabe 2
In dieser Aufgabe erstellt ihr selbst eine Dockerfile.

Setze das `nginx`-Image als Basis ein und erweitere es wie folgt: 
- Es soll eine HTML-Datei beinhalten, in deren Inhalt "Hello World" steht. 
- Die HTML-Datei soll unter `/usr/share/nginx/html/index.html` im Image vorhanden sein.
- Baue das Image und starte einen Container davon. Der laufende Container soll unter Port 9000 erreichbar sein und obige HTML-Seite anzeigen.
- Prüfe, ob alles funktioniert, indem du http://localhost:9000 aufrufst.

### Hinweise:

- Für diese Aufgabe reichen die Dockerfile-Direktiven `FROM` und `COPY`
- Um einem Image direkt beim Build einen Namen zu geben, verwende das `-t` Flag. Beispiel: `docker build . -t my-nginx`.
- NGINX lauscht innerhalb Container standardmäßig auf Port 80. Auf dem Host soll NGINX aber unter Port 9000 erreichbar sein. Dabei hilft dir das `-p` Argument. Beispiel: `docker run -p 9000:80 my-nginx`
