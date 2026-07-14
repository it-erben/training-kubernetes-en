# Lab 11: Multi-stage build

You now convert the existing single-stage Dockerfile into a multi-stage build. The build stage produces the jar,
the runtime stage contains only the bare minimum needed to run it.

## Convert the Dockerfile to multi-stage

Both stages go into the same `Dockerfile`.

### Stage 1 (Builder)

- Use the base image `maven:3-eclipse-temurin-17`

> Hint: You define a stage in a multi-stage build with `AS`, e.g. `FROM maven:3-eclipse-temurin-17 AS build`

- Set the working directory to `/workspace`
- Copy the `src/` directory and the `pom.xml` into the image
- Build the jar with Maven

### Stage 2 (Runtime)

- Use the base image `eclipse-temurin:17-jre`
- Copy **only** the jar from stage 1 to `/app/app.jar`

> Hint: To copy a file from another stage, use
> `COPY --from=<STAGE_NAME>, e.g. COPY --from=build`

- Set a correct `CMD` or entrypoint

## Create a dockerignore

Create a file `.dockerignore` next to the `Dockerfile` and add the directories `target` and `.git`

## Build and test the image

Build the image with Docker and test that it works.
