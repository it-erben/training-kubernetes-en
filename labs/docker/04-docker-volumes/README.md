# Docker Volumes

In dieser kurzen Übung schauen wir uns an, wie Bind Mounts in Docker funktionieren.
Dazu findest du in diesem Verzeichnis eine Datei [script.py](script.py), welche ein einfaches Python-Skript enthält.

Starte einen Container vom `python:3`-Image. Gib' als Startprogramm `bash` an. Mounte das Verzeichnis, in dem das Python-Skript liegt, in das Containerverzeichnis `/tmp/scripts`:

---

Du befindest dich nun in einer Bash-Sitzung innerhalb des Containers. Führe das Skript aus:

```shell
python /tmp/scripts/script.py
```

Merke dir, was das Skript auf das Terminal druckt.

Ändere nun mit einem Texteditor **während der Container noch läuft** den Inhalt des Python-Skripts in [script.py](script.py) ab, sodass das Skript "Hallo Welt" druckt statt "Hello World". Speichere die Änderung und führe dann nochmal den Befehl im Container aus:

> Was stellst du fest?

Wenn du fertig bist, kannst du mit STRG+C oder `exit` den Container verlassen.
