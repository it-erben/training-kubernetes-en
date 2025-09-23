# Multistage-Build

Du wandelst nun die bestehende Single-Stage-Dockerfile in einen Multistage-Build um. Der Build-Stage erzeugt das Jar, der Runtime-Stage enthält nur das Nötigste zum Ausführen.

## Dockerfile in Multistage umbauen

Beide Stages kommen in die selbe `Dockerfile`.

### Stage 1 (Builder)

- Verwende das Base-Image `maven:3-eclipse-temurin-17`

> Hinweis: man definiert eine Stage in einem Multi-Stage-Build mit `AS`, z.B.
> `FROM maven:3-eclipse-temurin-17 AS build`
- Setze das Arbeitsverzeichnis auf `/workspace`
- Kopiere das Verzeichnis `src/` sowie die `pom.xml` in das Image 
- Baue das Jar mit Maven

### Stage 2 (Runtime)

- Verwende das Base-Image `eclipse-temurin:17-jre`
- Kopiere **nur** das Jar aus Stage 1 nach `/app/app.jar`

> Hinweis: Um eine Datei aus einer anderen Stage zu kopieren, verwende `COPY --from=<STAGE_NAME>, z.B. COPY --from=build`
- Setze einen korrekten `CMD` oder Entrypoint

## Dockerignore anlegen

Erzeuge neben der `Dockerfile` eine Datei `.dockerignore` und füge die Verzeichnisse `target` und `.git` hinzu

## Image bauen und testen

Baue nun mit Docker das Image und teste es danach auf Funktionsfähigkeit.
