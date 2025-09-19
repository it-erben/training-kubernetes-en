# Docker Container

## Übung 1: Container erstellen

In dieser Übung gehen wir das Erzeugen, Starten, Stoppen und Löschen von Containern durch.
Mache dich mit den Befehlen vertraut und lass dir ruhig etwas Zeit, die jeweiligen Ausgaben der Befehle zu verstehen.

- Erzeuge einen Container vom `httpd:latest` Image und nenne es "my-httpd"
- Lass' dir den Container mit dem ls-Befehl anzeigen (an das -a Flag denken)
- Starte den Container
- Lass dir den Zustand aller Container anzeigen und suche den `my-httpd`-Container
- Stoppe und lösche anschließend den Container

## Übung 2: Befehle ausführen

In dieser Übung üben wir nochmal, einen Container zu erzeugen und zu starten.
Anschließend benutzen wird den `exec`-Befehl, um auf einem laufenden Container Änderungen vorzunehmen.
Wir installieren dabei den Texteditor nano und führen ihn danach auf dem Container aus.

- Erzeuge einen neuen Container vom Image `nginx:latest`
- Führe die Befehle `apt-get update` und `apt-get install nano -y` auf dem Container aus.
- Verbinde dich mit dem Container durch eine Bash-Sitzung und starte `nano`. (Tipp: `-it`)
