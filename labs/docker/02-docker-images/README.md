# Docker Images

## Übung 1: Docker Images

Um uns näher mit dem Docker CLI vertraut zu machen, schauen wir uns die lokal heruntergeladenen Images an.
Liste dir zunächst mit dem Docker-CLI alle vorhandenen Images auf.

Lasse dir nun alle Details zum Image `python:3` ausgeben.

> - Ermittle das OS des Images `python:3`. Das Feld heißt im JSON `.Os`.
> - Wann wurde es angelegt? (Das Feld heißt `.Created`)
> - Welche Umgebungsvariablen sind definiert? (`.Config.Env`)

## Übung 2: Docker Image Tagging

Wir machen nun einige Übungen für das Arbeiten mit Tags in Docker. Du wirst sehen, dass man mit dem Tag-Befehl nicht nur ein Tag setzen kann, sondern auch einen Namens-Alias.

- Finde über DockerHub das offizielle node-Image und pulle das image mit dem latest-Tag
- Erstelle nun ein Alias für dieses Image: `my-node:latest`. Du setzt also sowohl den Namen als auch das Tag des Images.
- Zeige dir mit docker inspect alle Tags an, die das Image `node` bei dir lokal hat
- Lösche als nächstes das Tag `my-node:latest`. Merke dir, was das CLI zurückgibt.
- Anschließend löschst du den Tag `node:latest`

> Vergleiche jeweils die Ausgabe, die dir das CLI in den letzten Kommandos zurückgibt. Warum sind sie unterschiedlich?
