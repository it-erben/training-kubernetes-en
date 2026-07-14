# Lab 10: Build in Docker

Building on the previous task: rework your Dockerfile so that the Maven build also runs inside the container.

- Use the base image `maven:3.9-eclipse-temurin-17` to have Maven available in the image
- Copy the application's entire source code into the image
- Run a Maven build inside the image (`RUN mvn clean install`)
- Copy the jar produced in the `target` directory into the `/app` directory
- Execute the jar in the image's `CMD`

Then test whether the image still works.
