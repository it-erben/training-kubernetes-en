# 1  Docker Images
Um uns näher mit dem Docker CLI vertraut zu machen, schauen wir uns die lokal heruntergeladenen Images an.

```shell
docker images
```

```shell
docker inspect python:3
```
Diese Ausgabe ist sehr umfangreich und wegen des JSON-Formats nicht leicht zu lesen.
Mit dem `--format` Argument können wir mithilfe der Go-Template-Sprache auch einzelne Elemente der Image-Beschreibung ermitteln. 

```shell
docker inspect python:3 --format "{{.Size}}"
```

Fragen:
- Ermittle das OS des Images `python:3`. Das Feld heißt im JSON `.Os`.
- Wann wurde es angelegt? (Das Feld heißt `.Created`)
- Welche Umgebungsvariablen sind definiert? (`.Config.Env`)

# 2 Docker Image Tagging
Finde über DockerHub das offizielle node-Image und pulle das image mit dem latest-Tag

```shell
docker pull node:latest
```

Erstelle nun ein Alias für dieses Image mit dem Namen my-node:

```shell
docker image tag node:latest my-node
```

Zeige dir mit docker inspect alle Tags an, die das Image „node“ bei dir lokal hat

```shell
docker image inspect node:latest --format "{{ .RepoTags }}"
```
**Frage:** Schau' dir die beiden Tags im Ergebnis genau an. 
Wir haben im Befehl `docker image tag` oben als zweiten Parameter `my-node` übergeben. 
Was ist daraus geworden?

--- 
Lösche als nächstes die Image-Referenz "my-node".

```shell
docker image rm my-node:latest
```
Merke dir, was das CLI zurückgibt. Anschließend löschst du den Tag node:latest

```shell
docker image rm node:latest
```

**Frage:** Vergleiche jeweils die Ausgabe, die dir das CLI in den letzten Kommandos zurückgibt. Warum sind sie unterschiedlich?
