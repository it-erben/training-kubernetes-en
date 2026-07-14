# Solution: Multistage build

Dockerfile:

```Dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /workspace/target/*SNAPSHOT.jar /app/app.jar
CMD ["java","-jar","/app/app.jar"]
```

`.dockerignore`:

```text
target
.git
```

Build & test:

```bash
docker build -t hello-docker-multistage .
docker run -d --name hello-docker-multistage -p 8080:8080 hello-docker-multistage
curl http://localhost:8080/hello
docker rm -f hello-docker-multistage && docker rmi hello-docker-multistage
```
