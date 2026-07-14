# Lab 04: Docker Volumes

This short exercise shows how bind mounts work in Docker. In this directory you will find
[script.py](script.py), a small Python script.

**`script.py`:**

```python
print("Hello world2!")
```

Start a container from the `python:3` image with `bash` as the startup program, and mount the directory
containing the Python script to `/tmp/scripts` inside the container.

> Hints:
>
> - You start an interactive container with the `run` command and the `-it` flags.
> - The startup program goes at the very end of the `run` command.
> - Directories are mounted with `-v <HOST_PATH>:<CONTAINER_PATH>`
> - If you want to mount the current directory you are in on the host, use
>   `-v "${PWD}:<CONTAINER_PATH>"`

---

Because you used `bash` as the startup command, you are now in a Bash session inside the
container. Run the mounted script:

```shell
python /tmp/scripts/script.py
```

Remember what the script prints to the terminal.

Now, **while the container is still running**, edit [script.py](script.py) so that it prints "Goodbye world"
instead of "Hello world". Save the change and run the command inside the container again. What do you observe?

When you are done, leave the container with CTRL+C or `exit`.
