# Docker Images

## Übung 1: Images inspizieren

Wir verschaffen uns einen Überblick über lokal verfügbare Images und sehen uns ein bestimmtes Image im Detail an.

- Liste zuerst alle lokal vorhandenen Images auf.
- Inspiziere danach das Image `python:3` im Detail mit dem `inspect`-Befehl.

Beantworte die folgenden Fragen (achte auf die JSON-Felder im Output):
- Welches **OS** hat das Image? (`.Os`)
- Wann wurde es **erstellt**? (`.Created`)
- Welche **Umgebungsvariablen** sind definiert? (`.Config.Env`)

> Tipp: Verwende zur gezielten Ausgabe z.B. `docker inspect --format '{{ .Os }}' python:3`.

---

## Übung 2: Image-Tagging

Wir üben den Umgang mit Tags und Aliassen.

* Lade mit dem `pull`-Befehl das Image `node:latest` herunter
* Vergib einen Alias mit dem Namen `my-node:latest`.

> Hinweis: Auch einen Alias setzt man mit dem `tag`-Befehl.

* Überprüfe, welche Tags das Image bei dir lokal hat (siehe Feld `.RepoTags`)
* Entferne zunächst den Alias-Tag `my-node:latest`.
* Entferne danach auch den Tag `node:latest`.

> Beobachte genau die Ausgaben des CLI: Worin unterscheiden sich die Rückmeldungen beim Entfernen? Was ist der Unterschied zwischen Tag löschen und Image löschen?

