# Docker Volumes

In this short exercise, we'll examine how **Bind Mounts** work in Docker.
You will find a file named **`script.py`** in this directory, which contains a simple Python script.

## Initial Setup

Start a container from the **`python:3`** image, specifying **`bash`** as the startup program.
While running, **mount the directory** where the Python script is located into the container directory **`/tmp/scripts`**.

> **Hints:**
>
>   * You start an interactive container using the **`run`** command with the **`-it`** arguments.
>   * The startup program is specified at the very end of the `run` command.
>   * Directories are mounted using **`-v <HOST_PATH>:<CONTAINER_PATH>`**.
>   * To mount the current directory you are in on the host, use **`-v "$(pwd):<CONTAINER_PATH>"`** (or **`-v "${PWD}:<CONTAINER_PATH>"`** or a similar shell-specific variable, depending on your environment, but **`$(pwd)`** is usually robust).

-----

## Execution and Observation

Since you used `bash` as the startup command, you are now in a Bash session inside the container. **Execute the script** you just mounted:

```shell
python /tmp/scripts/script.py
```

Note what the script prints to the terminal.

Now, while the container is still running, **modify the content of the Python script in `script.py`** on your host machine using a text editor. Change the script to print **"Hallo Welt"** instead of "Hello World." Save the change, and then run the command again inside the container. **What do you observe?**

When you are finished, you can leave the container by pressing **`CTRL+C`** or typing **`exit`**.
