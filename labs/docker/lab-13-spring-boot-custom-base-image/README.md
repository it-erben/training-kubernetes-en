# Lab 13: Custom base images with Spring

## Build a custom base image

- Create a file `Dockerfile.base` based on `eclipse-temurin:17-jre`.
- Create a user `spring`, set `WORKDIR` to `/app`.
- Set the environment variable `JAVA_OPTS="-Xmx512m"`.
- Build the image and remember its name

## Create the app image

- Adapt your app Dockerfile from task 1 so that it uses your base image.
- Copy your `Jar` to `/app/app.jar`, expose 8080

Now build and test your image.
