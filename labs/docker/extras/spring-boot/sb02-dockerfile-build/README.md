# Basis: Maven + JDK 17 (für Build UND Laufzeit)
FROM maven:3.9-eclipse-temurin-17

# Arbeitsverzeichnis im Container
WORKDIR /workspace

# --- Abhängigkeits-Cache vorbereiten ---
# 1) pom.xml kopieren und Dependencies cachen
COPY pom.xml .
RUN mvn -B -q -DskipTests dependency:go-offline

# --- Quellcode und Build ---
# 2) Quellen kopieren
COPY src ./src

# 3) Maven-Build im Container
RUN mvn -B -DskipTests package

# 4) Jar an definierten Ort ablegen
RUN mkdir -p /app && cp target/*.jar /app/app.jar

# Portdokumentation (Spring Boot default)
EXPOSE 8080

# 5) Anwendung starten
ENTRYPOINT ["java","-jar","/app/app.jar"]
