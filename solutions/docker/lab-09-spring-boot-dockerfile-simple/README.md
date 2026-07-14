# Solution: Simple Dockerfile

- Example controller:

  ```java
  @RestController
  public class HelloController {
      @GetMapping("/hello")
      public String hello() { return "Hello from Docker"; }
  }
  ```

- Build: `mvn clean package`
- Dockerfile:

  ```Dockerfile
  FROM eclipse-temurin:17-jre
  WORKDIR /app
  COPY target/hello-docker-0.0.1-SNAPSHOT.jar /app/app.jar
  CMD ["java","-jar","/app/app.jar"]
  ```

- Build & test the image:

  ```bash
  docker build -t hello-docker .
  docker run -d --name hello-docker -p 8080:8080 hello-docker
  curl http://localhost:8080/hello
  docker rm -f hello-docker && docker rmi hello-docker
  ```
