# Lab 09: Turning a Spring Boot application into an image the simple way with Dockerfiles

In this task you create a Docker image from a simple Spring Boot service. We choose a
simple approach without special plugins or multi-stage builds.

## Generate the project

Create an empty directory and use the [Spring Initializr](https://start.spring.io/) to generate a Spring Boot project
with the following properties:

- Project: Maven
- Language: Java
- Spring Boot Version: 3.x.x
- Group: de.gfu
- Artifact: hello-docker
- Dependencies: spring-boot-starter-web
- Packaging: Jar
- Java: 17

## Add the code

Create a controller that returns a short text on `GET /hello` (e.g. "Hello from Docker"). Then run
a Maven install once to verify that everything works.

## Create the Dockerfile

Create a file `Dockerfile` with the following properties:

- Base image: `eclipse-temurin:17-jre`
- Copy the jar produced by the Maven build in the `target` directory to `/app/app.jar` in the image
- Configure the `CMD` or entrypoint so that the jar is executed with `java` when the container starts.

## Build and test the image

- Build the jar with Maven
- Build the Docker image
- Start the container on port 8080 and test whether the endpoint works

## Clean up

- Stop the container and delete the container and the image
