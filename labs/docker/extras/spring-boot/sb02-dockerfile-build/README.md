# Build in Docker

Aufbauend auf der letzten Aufgabe: Baue dein Dockerfile so um, dass auch der Maven-Build innerhalb des Containers stattfindet.

- Kopiere den Source-Code der Anwendung komplett in das Image
- Mache einen Maven-Build im Image (`RUN mvn clean install`)
- Kopiere die Jar, das im `target`-Verzeichnis entsteht, in das `/app`-Verzeichnis
- Führe die Jar im `CMD` des Images aus

Teste danach, ob das Image immer noch funktionsfähig ist.
