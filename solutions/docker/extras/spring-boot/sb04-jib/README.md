# Lösung: Container-Image mit dem Jib-Plugin (Maven)

> Ausgangspunkt: Spring-Boot-Projekt (vom Initializr) liegt im aktuellen Verzeichnis.

## `pom.xml` – Jib-Plugin einbinden

```xml
<project>
  <!-- ... -->

  <properties>
    <jib.version>3.4.3</jib.version>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <build>
    <plugins>
      <plugin>
        <groupId>com.google.cloud.tools</groupId>
        <artifactId>jib-maven-plugin</artifactId>
        <version>${jib.version}</version>
        <configuration>
          <!-- Lokaler Image-Name/Tag -->
          <from>
            <image>eclipse-temurin:17-jre</image>
          </from>
          <to>
            <image>my-spring-boot-jib:latest</image>
          </to>

          <container>
            <!-- Optional: JVM-Flags und Port-Dokumentation -->
            <jvmFlags>
              <jvmFlag>-XX:MaxRAMPercentage=75.0</jvmFlag>
            </jvmFlags>
            <ports>
              <port>8080</port>
            </ports>
            <environment>
              <SPRING_PROFILES_ACTIVE>prod</SPRING_PROFILES_ACTIVE>
            </environment>
          </container>
        </configuration>
      </plugin>
    </plugins>
  </build>

  <!-- ... -->
</project>
```

## Lokales Image bauen

```bash
mvn -DskipTests package jib:dockerBuild -Dimage=my-spring-boot-jib:latest
```

## Container starten

```bash
docker run --rm -d --name spring-jib -p 8080:8080 my-spring-boot-jib:latest
# Test (in neuer Shell)
curl -s http://localhost:8080/actuator/health || curl -s http://localhost:8080
```

## Cleanup

```bash
docker stop spring-jib
docker rm spring-jib 2>/dev/null || true
docker rmi my-spring-boot-jib:latest
```
