# Docker Images

## Exercise 1: Inspecting Images

We'll start by getting an overview of locally available images and then look at a specific image in detail.

* First, **list all locally present images**.
* Then, **inspect the `python:3` image** in detail using the `inspect` command.

Answer the following questions (pay attention to the JSON fields in the output):
* What **OS** does the image have? (`.Os`)
* When was it **created**? (`.Created`)
* What **environment variables** are defined? (`.Config.Env`)

> **Tip:** Use the `--format` option for targeted output, e.g., `docker inspect --format '{{ .Os }}' python:3`.

---

## Exercise 2: Image Tagging

We will practice managing tags and aliases.

* **Pull** the image **`node:latest`** using the `pull` command.
* Assign an **alias** named **`my-node:latest`** to this image.

> **Hint:** You also use the `tag` command to set an alias.

* Verify which tags the image has locally (check the field `.RepoTags` in the `inspect` output).
* First, **remove the alias tag `my-node:latest`**.
* Then, **remove the original tag `node:latest`**.

> **Observe the CLI output closely:** How do the responses differ when removing them? What is the difference between deleting a tag and deleting an image?
