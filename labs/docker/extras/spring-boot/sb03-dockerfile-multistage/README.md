# Multistage-Build

Du wandelst nun die bestehende Single-Stage-Dockerfile in einen Multistage-Build um. Der Build-Stage erzeugt das Jar, der Runtime-Stage enthält nur das Nötigste zum Ausführen.

## Dockerfile in Multistage umbauen

### Stage 1 (Builder)

- Verwende das Base-Image `maven:3-eclipse-temurin-17`
- Setze das Arbeitsverzeichnis auf `/workspace`
- Kopiere die `pom.xml` und führe einen Dependency-Cache aus (`mvn -q -DskipTests dependency:go-offline`)
- Kopiere das Verzeichnis `src/` und baue das Jar mit Maven

### Stage 2 (Runtime)

- Kopiere **nur** das Jar aus Stage 1 nach `/app/app.jar`
- Setze einen korrekten Entrypoint

## Dockerignore anlegen

Erzeuge eine Datei `.dockerignore` und füge die Verzeichnisse `target` und `.git` hinzu

## Image bauen und testen

Baue nun mit Docker das Image und teste es danach auf Funktionsfähigkeit.
