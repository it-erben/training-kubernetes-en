# Abschlussübung: Alles zusammenführen

Ziel: Ein vorhandenes Node.js-Programm containerisieren, per Bind Mount Inhalte injizieren, in einem eigenen Netzwerk erreichbar machen und am Ende sauber aufräumen.

---

## Schritt 1 – Dockerfile erstellen

- Die Datei `app.js` stellt einen HTTP-Webserver bereit. Sorge dafür, dass der Server auf **0.0.0.0** und **Port 3000** lauscht.
- Erstelle ein Dockerfile mit:
    - festem Basisimage (z. B. `node:20-alpine`)
    - sinnvollem `WORKDIR`
    - Kopieren der benötigten Dateien
    - Start über `CMD`
    - optional `EXPOSE 3000`
- Baue ein Image mit einem eindeutigen Namen (z.B. Präfix der Übung).

**Erfolgskriterium:** Image gebaut; Container kann daraus gestartet werden.

---

## Schritt 2 – Container starten

- Starte einen Container aus deinem Image und mache den Dienst lokal erreichbar.
- Prüfe die Erreichbarkeit per Browser oder HTTP-Client.

**Erfolgskriterium:** HTTP-Response (Status 200) mit erwarteter Antwort der App.

---

## Schritt 3 – Bind Mount testen

`app.js` soll den Inhalt der Datei `/tmp/content/file.txt` zurückgeben, wenn diese existiert.

- Starte einen (neuen) Container **mit** Bind Mount auf `/tmp/content` (Host-Verzeichnis frei wählbar).
- Lege im **Host-Verzeichnis** eine `file.txt` an und ändere deren Inhalt.
- Rufe den Endpunkt erneut auf und beobachte die Änderung.

**Hinweis:** Achte darauf, dass kein bereits laufender Container das Port-Mapping blockiert.

**Erfolgskriterium:** Der Response enthält den jeweils aktuellen Inhalt der Host-`file.txt`.

---

## Schritt 4 – Netzwerk aufbauen

- Erzeuge ein eigenes, benutzerdefiniertes Docker-Netzwerk.
- Starte den Webserver-Container **im** neuen Netzwerk (interner Port 3000).
- Starte einen zweiten, leichten Container (z. B. `alpine`/`busybox`) **im selben Netzwerk**.
- Rufe vom zweiten Container aus den Webserver **per Container-Namen** und **Port 3000** auf.

**Hinweis:** Für Container-zu-Container-Zugriff ist kein Port-Mapping auf den Host nötig.

**Erfolgskriterium:** HTTP-Request aus dem zweiten Container an `http://<webserver-name>:3000` liefert die erwartete Antwort.

---

## Schritt 5 – Aufräumen

- Stoppe alle Container der Übung.
- Entferne **nur** die in dieser Übung erstellten Container, Images, Bind-Mount-Inhalte und das Netzwerk.
    - Nutze dafür konsistente Namen oder ein Label, das du in allen Ressourcen gesetzt hast.

**Erfolgskriterium:** `docker ps`, `docker images` und die Netzwerk-/Volume-Übersichten zeigen keine Ressourcen mit dem Übungspräfix/Label.

---
