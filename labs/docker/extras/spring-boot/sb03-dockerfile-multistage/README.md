# Multistage-Build

Du wandelst nun die bestehende Single-Stage-Dockerfile in einen Multistage-Build um. Der Build-Stage erzeugt das Jar, der Runtime-Stage enthält nur das Nötigste zum Ausführen.

## Dockerfile in Multistage umbauen

### Stage 1 (Builder)

- Verwende das Base-Image `maven:3-eclipse-temurin-17`
- Setze das Arbeitsverzeichnis auf `/workspace`
- Kopiere das Verzeichnis `src/` in das Image 
- Baue das Jar mit Maven

### Stage 2 (Runtime)

- Kopiere **nur** das Jar aus Stage 1 nach `/app/app.jar`
- Setze einen korrekten `CMD` oder Entrypoint

## Dockerignore anlegen

Erzeuge neben der `Dockerfile` eine Datei `.dockerignore` und füge die Verzeichnisse `target` und `.git` hinzu

## Image bauen und testen

Baue nun mit Docker das Image und teste es danach auf Funktionsfähigkeit.
