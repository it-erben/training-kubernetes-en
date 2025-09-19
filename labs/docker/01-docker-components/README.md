# Docker Basics

## Übung 1: Unser erster Docker-Container

Um uns langsam an Docker heranzutasten, starten wir einen Container vom Python 3-Image und testen, ob Python auch wirklich funktioniert

```shell
docker run -it --rm python:3 python
```

Lass' dir nun den heutigen Tag ausgeben.

```python
from datetime import date
str(date.today())
# '202X-12-06'
```

Schließe nun das Fenster.


## Übung 2: Docker Client

Manchmal verhält sich das Docker CLI nicht so, wie es soll. Es ist wichtig zu wissen, wie man sich Informationen über die lokale Docker-Installation beschaffen kann.

```shell
docker version

```

Ermittle mit docker version folgende Informationen:

- Welche Version von Docker Desktop ist installiert?
- Welche Version der Docker Engine ist installiert?

## Übung 3: Docker Daemon

Wir können uns auch Informationen über den Daemon ausgeben lassen. Der Docker Client wird dazu eine Verbindung zum Host aufbauen – der in unserem Fall auf der gleichen Maschine läuft.

```shell
docker info
```

Ermittle die folgenden Informationen:

- Welche Runtime verwendet der Daemon zum Start der Container? (Hinweis: "Default Runtime")
- Welche sind insgesamt verfügbar? (Hinweis: "Runtimes")
- Welches OS hat der Host?
- Wie viele CPUs stehen zur Verfügung?
- Wieviel Memory steht zur Verfügung?
