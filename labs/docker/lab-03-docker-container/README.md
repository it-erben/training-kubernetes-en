# Lab 03: Docker Containers

## Exercise 1: Creating containers

In this exercise we walk through creating, starting, stopping and deleting containers. Familiarize yourself with the
commands and take your time to understand the output of each command.

- Create a container from the `httpd:latest` image using the `create` command and name the container `my-httpd`
- Display the container with the `docker container ls` command (remember the `-a` flag, since it has not been
  started yet)
- Start the container with the `start` command
- Display the state of all containers with the `docker ps` command and find the `my-httpd` container
- Then stop and delete the container

## Exercise 2: Executing commands

In this exercise we practice creating and starting a container once more. Afterwards we use the
`exec` command to make changes to a running container. We install the text editor `nano` and
then run it inside the container.

- Create a new container from the image `nginx:latest`
- Use `docker exec` to run the commands `apt-get update` and `apt-get install nano -y` inside the container.

> The commands above contain spaces. Remember to wrap them in quotes.

- Connect to the container via a Bash session and start `nano`. (Tip: `docker exec -it <CONTAINER> bash`)

> You have now learned how to connect to a container after the fact. Feel free to delete the
> container now.
