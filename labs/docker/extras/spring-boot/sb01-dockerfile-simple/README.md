# Spring Boot-Anwendung einfach mit Dockerfiles zu Images machen

In dieser Aufgabe erstellst du ein Docker-Image von einem einfachen Spring Boot-Service. Dabei wählen wir einen einfachen Ansatz ohne spezielle Plugins oder Multi-Stage-Builds.

## Projekt erzeugen

Erzeuge ein leeres Verzeichnis und erzeuge mit dem [Spring Initializr](https://start.spring.io/) ein Spring Boot-Projekt mit folgenden Eigenschaften:

- Project: Maven
- Language: Java
- Spring Boot Version: 3.x.x
- Group: de.gfu
- Artifact: hello-docker
- Dependencies: spring-boot-starter-web
- Packaging: Jar
- Java: 17

## Code hinterlegen

Lege einen Controller an, der auf `GET /hello` einen kurzen Text zurückgibt (z. B. "Hello from Docker").
Führe nun einmal einen Maven-Install aus um zu testen, das alles funktioniert.

## Dockerfile erstellen

Lege eine Datei `Dockerfile` an mit folgenden Eigenschaften:

- Basis-Image: `eclipse-temurin:17-jre`
- Kopiere das Jar, was beim Maven-Build im `target`-Verzeichnis entsteht, nach `/app/app.jar` im Image
- Konfiguriere den `CMD` bzw. Entrypoint so, dass die Jar beim Start des Containers mit `java` ausgeführt wird.

## Image bauen und testen

- Baue des Jar mit Maven
- Baue das Docker-Image
- Starte den Container auf Port 8080 und teste, ob der Endpunkt funktioniert

## Aufräumen

- Stoppe den Container und lösche Container und Image
