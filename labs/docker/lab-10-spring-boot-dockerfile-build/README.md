# Lab 10: Build in Docker

Building on the previous task: Rework your Dockerfile so that the Maven build also takes place inside the
container.

- Use the base image `maven:3.9-eclipse-temurin-17` to have Maven available in the image
- Copy the application's source code completely into the image
- Run a Maven build inside the image (`RUN mvn clean install`)
- Copy the jar produced in the `target` directory into the `/app` directory
- Execute the jar in the image's `CMD`

Afterwards, test whether the image still works.
