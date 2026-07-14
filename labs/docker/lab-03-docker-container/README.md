# Lab 03: Docker Containers

## Exercise 1: Creating containers

In this exercise we walk through creating, starting, stopping and deleting containers. Take your time with each
command and read its output.

- Create a container from the `httpd:latest` image using the `create` command and name the container `my-httpd`
- Display the container with the `docker container ls` command (remember the `-a` flag, since it has not been
  started yet)
- Start the container with the `start` command
- Display the state of all containers with the `docker ps` command and find the `my-httpd` container
- Then stop and delete the container

## Exercise 2: Executing commands

We create and start a container once more, then use the `exec` command to change it while it is
running: we install the text editor `nano` and run it inside the container.

- Create a new container from the image `nginx:latest`
- Use `docker exec` to run the commands `apt-get update` and `apt-get install nano -y` inside the container.

> The commands above contain spaces. Remember to wrap them in quotes.

- Connect to the container via a Bash session and start `nano`. (Tip: `docker exec -it <CONTAINER> bash`)

> That is how you connect to a running container after the fact. Feel free to delete the
> container now.
