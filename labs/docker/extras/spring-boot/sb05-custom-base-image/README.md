# Übungsaufgabe zu Custom Base Images mit Spring

## Custom Base Image bauen

- Erstelle eine Datei `Dockerfile.base` auf Basis `eclipse-temurin:17-jre`.
- Lege User `spring` an, setze `WORKDIR` auf `/app`.
- Setze die Umgebungsvariable `JAVA_OPTS="-Xmx512m"`.
- Baue das Image und merke dir den Namen

## App-Image erstellen

- Passe dein App-Dockerfile aus Aufgabe 1 an, sodass es dein Baseimage verwendet.
- Kopiere dein `Jar` nach `/app/app.jar`, exponiere 8080

Baue und teste nun dein Image
