# Docker Volumes

In dieser kurzen Übung schauen wir uns an, wie Bind Mounts in Docker funktionieren.
Dazu findest du in diesem Verzeichnis eine Datei [script.py](script.py), welche ein einfaches Python-Skript enthält.

Starte einen Container vom `python:3`-Image. Gib' als Startprogramm `bash` an. 
Mounte dabei das Verzeichnis, in dem das Python-Skript liegt, in das Containerverzeichnis `/tmp/scripts`.

> Hinweise:
> - Einen interaktiven Container startet man, indem man den `run`-Befehl mit den Argumenten `-it` benutzt.
> - Das Startprogramm gibt man ganz am Ende des `run`-Befehls an.
> - Verzeichnisse mountet man mit `-v <HOST_PFAD>:<CONTAINER_PFAD>`
> - Wenn ihr das aktuelle Verzeichnis, in dem ihr euch auf dem Host befindet, mounten wollt, nutzt `-v "${CMD}:<CONTAINER_PFAD>"`

---

Dadurch, dass du `bash` als Startbefehl verwendet hast, befindest du dich nun in einer Bash-Sitzung innerhalb des Containers. Führe nun das Skript aus, das du gemountet hast:

```shell
python /tmp/scripts/script.py
```

Merke dir, was das Skript auf das Terminal druckt.

Ändere nun mit einem Texteditor **während der Container noch läuft** den Inhalt des Python-Skripts in [script.py](script.py) ab, sodass das Skript "Hallo Welt" druckt statt "Hello World". Speichere die Änderung und führe dann nochmal den Befehl im Container aus. Was stellst du fest?

Wenn du fertig bist, kannst du mit STRG+C oder `exit` den Container verlassen.
