# Lab 04: Docker Volumes

In this short exercise we look at how bind mounts work in Docker. In this directory you will find a file
[script.py](script.py) containing a simple Python script.

**`script.py`:**

```python
print("Hello world2!")
```

Start a container from the `python:3` image. Specify `bash` as the startup program. While doing so, mount the
directory containing the Python script into the container directory `/tmp/scripts`.

> Hints:
>
> - You start an interactive container by using the `run` command with the `-it` arguments.
> - The startup program is specified at the very end of the `run` command.
> - Directories are mounted with `-v <HOST_PATH>:<CONTAINER_PATH>`
> - If you want to mount the current directory you are in on the host, use
>   `-v "${PWD}:<CONTAINER_PATH>"`

---

Because you used `bash` as the startup command, you are now in a Bash session inside the
container. Now run the script you mounted:

```shell
python /tmp/scripts/script.py
```

Remember what the script prints to the terminal.

Now, **while the container is still running**, use a text editor to change the content of the Python script in
[script.py](script.py) so that the script prints "Goodbye world" instead of "Hello world". Save the change and then
run the command inside the container again. What do you observe?

When you are done, you can leave the container with CTRL+C or `exit`.
