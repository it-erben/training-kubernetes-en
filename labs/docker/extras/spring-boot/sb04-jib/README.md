# Übung: Container-Image mit dem Jib-Plugin in Maven bauen

In dieser Aufgabe erstellst du ein Container-Image **ohne Dockerfile** direkt mit dem Maven-Plugin [Jib](https://github.com/GoogleContainerTools/jib).  
Ausgangspunkt ist ein Spring Boot-Service, den du zuvor mit dem [Spring Initializr](https://start.spring.io/) erzeugt hast und der im aktuellen Verzeichnis liegt.

---

## Schritt 1 – Jib-Plugin einbinden

- Öffne die `pom.xml` deines Projekts.
- Füge das Jib-Plugin in den Abschnitt `<plugins>` ein.

_Hinweis: Jib hat eine eigene Plugin-Gruppe `com.google.cloud.tools` und die aktuelle Version findest du in der Dokumentation._

---

## Schritt 2 – Lokales Image bauen

- Baue dein Projekt und erzeuge dabei ein Docker-Image.
- Verwende dabei ein eigenes Tag, z. B. `my-spring-boot-jib:latest`.

_Hinweis: Mit einem einfachen Maven-Befehl wird der Build ausgeführt – du brauchst kein Dockerfile und keine Docker-Daemon-Verbindung._

---

## Schritt 3 – Container starten

- Starte einen Container aus deinem mit Jib erstellten Image.
- Teste, ob dein Spring Boot-Service über den Browser oder `curl` erreichbar ist.

_Hinweis: Spring Boot lauscht standardmäßig auf Port 8080._

---

## Schritt 4 – Cleanup

- Stoppe und lösche den Container.
- Entferne das erstellte Image.

---
