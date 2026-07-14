# Lab 12: Building a container image with the Jib Maven plugin

In this task you create a container image **without a Dockerfile**, directly with the Maven plugin
[Jib](https://github.com/GoogleContainerTools/jib).  
The starting point is the Spring Boot service you generated earlier with the
[Spring Initializr](https://start.spring.io/); it lives in the current directory.

---

## Step 1 – Add the Jib plugin

- Open the `pom.xml` of your project.
- Add the Jib plugin to the `<plugins>` section. Remember to use `<from>...</from>` with a base image such as
  Eclipse Temurin

> You can find setup instructions for Maven
> [here](https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin#quickstart).

---

## Step 2 – Build a local image

Build your project and create a Docker image in one go: `mvn compile jib:dockerBuild`

> You do not need a Dockerfile or a Docker daemon connection

---

## Step 3 – Start a container

- Start a container from the image you built with Jib.
- Test whether your Spring Boot service is reachable in the browser or with `curl`.

---

## Step 4 – Cleanup

- Stop and delete the container.
- Remove the image you built.

---
