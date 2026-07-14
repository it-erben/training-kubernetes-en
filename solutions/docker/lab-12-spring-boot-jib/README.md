# Solution: Jib

Plugin snippet in `pom.xml`:

```xml
<plugin>
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>jib-maven-plugin</artifactId>
  <version>3.4.1</version>
  <configuration>
    <from><image>eclipse-temurin:17-jre</image></from>
    <to><image>hello-docker:jib</image></to>
  </configuration>
</plugin>
```

Build & Test:

```bash
mvn compile jib:dockerBuild    # builds hello-docker:jib locally without a Dockerfile
docker run -d --name hello-jib -p 8080:8080 hello-docker:jib
curl http://localhost:8080/hello
docker rm -f hello-jib && docker rmi hello-docker:jib
```
