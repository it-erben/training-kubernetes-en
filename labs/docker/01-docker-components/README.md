# Docker Basics

## Übung 1: Erster Container – Hello World

Starte einen Container, um zu prüfen, ob Docker auf deinem Rechner funktioniert:

```shell
docker run hello-world
```

Du solltest eine Begrüßungsnachricht von Docker sehen.  
Damit weißt du: Docker Engine und Docker Daemon laufen.

---

## Übung 2: Python im Container

Starte einen interaktiven Container mit Python:

```shell
docker run -it --rm python:3 python
```

Prüfe im Python-Prompt das heutige Datum:

```python
from datetime import date
print(date.today())
```

Die Ausgabe sollte in etwa so aussehen (abhängig vom heutigen Datum):

```
2025-09-21
```

Beende die Python-Sitzung mit `exit()` oder `CTRL+D`.

---

## Übung 3: Docker Client

Manchmal verhält sich das Docker CLI nicht so, wie man es erwartet.  
Es ist wichtig zu wissen, wie man sich Informationen zur Installation anzeigen lassen kann:

```shell
docker version
```

Ermittle und notiere:
- Welche Version von **Docker Desktop** ist installiert?
- Welche Version der **Docker Engine** ist installiert?

👉 Hinweis: Die Angaben findest du in den Abschnitten `Client` und `Server`.

---

## Übung 4: Docker Daemon

Mit dem folgenden Befehl bekommst du Informationen über den Docker-Daemon:

```shell
docker info
```

Beantworte die folgenden Fragen:
- Welche **Default Runtime** verwendet der Daemon?
- Welche **Runtimes** sind insgesamt verfügbar?
- Welches **Operating System** hat der Host?
- Wie viele **CPUs** stehen zur Verfügung?
- Wieviel **Memory** steht zur Verfügung?

> Tipp: Scrolle im Output und suche gezielt nach diesen Feldern.
