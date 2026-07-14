# Lab 09: A simple Dockerfile for a Spring Boot application

In this task you create a Docker image from a small Spring Boot service, deliberately without
special plugins or multi-stage builds.

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

Create a file `Dockerfile`:

- Base image: `eclipse-temurin:17-jre`
- Copy the jar produced by the Maven build in the `target` directory to `/app/app.jar` in the image
- Configure the `CMD` or entrypoint so that the container runs the jar with `java` on start.

## Build and test the image

- Build the jar with Maven
- Build the Docker image
- Start the container on port 8080 and test whether the endpoint works

## Clean up

- Stop the container, then delete it together with the image
