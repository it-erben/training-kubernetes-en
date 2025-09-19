# ---------- Stage 1: Builder ----------
FROM maven:3-eclipse-temurin-17 AS builder
WORKDIR /workspace

# nur pom.xml für besseren Cache
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

# jetzt Quellcode und Build
COPY src ./src
RUN mvn -B -DskipTests package

# ---------- Stage 2: Runtime ----------
FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app

# nur das fertige Jar übernehmen
COPY --from=builder /workspace/target/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
