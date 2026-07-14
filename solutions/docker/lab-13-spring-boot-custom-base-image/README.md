# Solution: Custom Base Image

`Dockerfile.base`:

```Dockerfile
FROM eclipse-temurin:17-jre
RUN useradd -m spring
USER spring
WORKDIR /app
ENV JAVA_OPTS="-Xmx512m"
```

Build the base image: `docker build -f Dockerfile.base -t spring-base:17 .`

App Dockerfile:

```Dockerfile
FROM spring-base:17
COPY target/*SNAPSHOT.jar /app/app.jar
EXPOSE 8080
CMD ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]
```

Build & Test:

```bash
docker build -t hello-docker-custom .
docker run -d --name hello-custom -p 8080:8080 hello-docker-custom
curl http://localhost:8080/hello
docker rm -f hello-custom && docker rmi hello-docker-custom spring-base:17
```
