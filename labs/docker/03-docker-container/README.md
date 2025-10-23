# Docker Containers

## Exercise 1: Container Lifecycle Management

In this exercise, we will practice the process of **creating, starting, stopping, and deleting** containers. Take your time to become familiar with the commands and understand their output.

* **Create** a container from the **`httpd:latest`** image using the `create` command and name the container **`my-httpd`**.
* **List** the container using the **`docker container ls`** command. (Remember the **`-a`** flag, as the container hasn't been started yet).
* **Start** the container using the `start` command.
* **List** the status of all containers with the **`docker ps`** command and locate the `my-httpd` container.
* Finally, **stop and delete** the container.

---

## Exercise 2: Executing Commands in a Container

In this exercise, we'll practice creating and starting a container again. Afterward, we'll use the **`exec`** command to make changes to a running container. We will install the text editor `nano` and then run it inside the container.

* **Create and start** a new container from the **`nginx:latest`** image (you can combine `create` and `start` or use `run`).
* Using **`docker exec`**, run the commands **`apt-get update`** and **`apt-get install nano -y`** inside the container.

> The commands above contain spaces. Remember to wrap them in quotation marks (e.g., `docker exec <CONTAINER_NAME> "command with spaces"`).

* **Connect** to the running container by opening a Bash session and **start `nano`**. (Hint: `docker exec -it <CONTAINER> bash`).

> You have now learned how to connect to a container after it's been started. Feel free to delete the container once you're done.
