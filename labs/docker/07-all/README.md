# Abschlussübung: Alles zusammenführen

In dieser Aufgabe setzt du dein Wissen aus allen vorangegangenen Übungen ein. Ziel ist es, ein vorhandenes Node.js-Programm in einen Container zu packen, es mit Volumes und Netzwerken zu kombinieren und am Ende alles wieder aufzuräumen.

---

## Schritt 1 – Dockerfile erstellen

- Du hast in diesem Verzeichnis bereits eine Node.js-Datei (`app.js`), die einen kleinen Webserver bereitstellt.
- Schreibe ein Dockerfile, das diese Anwendung in ein Image verpackt. Nutze `node:latest` als Base-Image. Führe im `CMD` den Befehl `node` aus und übergebe den Pfad zur `app.js`.
- Baue dein Image.

_Hinweis: Achte darauf, den richtigen Port zu veröffentlichen._

---

## Schritt 2 – Container starten

- Starte einen Container aus deinem Image.
- Stelle sicher, dass die Anwendung über den Browser oder `curl` erreichbar ist.

_Hinweis: Port-Mapping nicht vergessen._

---

## Schritt 3 – Volume einbinden

- Erzeuge ein Volume und binde es in deinen Container ein.
- Nutze es, um Daten auch nach dem Neustart des Containers zu behalten (z. B. für Logs oder Dateien).

---

## Schritt 4 – Netzwerk aufbauen

- Erzeuge ein eigenes Docker-Netzwerk.
- Starte einen zweiten Container (z. B. `alpine` oder `busybox`) im gleichen Netzwerk.
- Teste die Verbindung zwischen den Containern.

---

## Schritt 5 – Aufräumen

- Stoppe alle Container.
- Entferne Container, Images, Volumes und Netzwerke, die du in dieser Übung erstellt hast.

---

Ziel dieser Übung: Du gehst einmal den gesamten Lebenszyklus durch – vom vorhandenen Programm über Image und Container bis hin zu Volumes und Netzwerken, und schließlich der Bereinigung.
