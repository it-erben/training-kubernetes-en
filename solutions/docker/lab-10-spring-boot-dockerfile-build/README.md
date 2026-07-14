# Solution: Build inside the container

Example Dockerfile (single-stage):

```Dockerfile
FROM maven:3.9-eclipse-temurin-17
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn clean install
RUN mkdir -p /app && cp target/*SNAPSHOT.jar /app/app.jar
CMD ["java","-jar","/app/app.jar"]
```

Build & Test:

```bash
docker build -t hello-docker-build .
docker run -d --name hello-docker-build -p 8080:8080 hello-docker-build
curl http://localhost:8080/hello
docker rm -f hello-docker-build && docker rmi hello-docker-build
```
