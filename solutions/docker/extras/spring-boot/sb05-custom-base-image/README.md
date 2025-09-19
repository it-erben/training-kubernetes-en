# Lösung zu Custom Base Images mit Spring

## Base Dockerfile

```dockerfile
FROM eclipse-temurin:17-jre

# Non-root User/Group
RUN addgroup --system spring && adduser --system --ingroup spring spring

# Timezone
ENV TZ=Europe/Berlin

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Xms128m"

USER spring
WORKDIR /app
```

## Build und Tag

```bash
docker build -f Dockerfile.base -t springboot-base:1.0 .
```

## Dockerfile für App-Image

```dockerfile
FROM springboot-base:1.0

# JAR hineinlegen
COPY target/*.jar /app/app.jar

# App-Ports (Standard Spring Boot: 8080)
EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]
```

## Build und Run

```bash
# App-Jar bauen
./mvnw -q -DskipTests package

# App-Image bauen
docker build -t demo-spring-app:local .

# Starten
docker run --rm -p 8080:8080 demo-spring-app:local

# Test in neuem Terminal
curl -s http://localhost:8080/actuator/health || true
```
