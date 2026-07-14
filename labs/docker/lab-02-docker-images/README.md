# Lab 02: Docker Images

## Exercise 1: Inspecting images

We get an overview of locally available images and take a detailed look at a specific image.

- First, list all locally available images.
- Then inspect the image `python:3` in detail using the `inspect` command.

Answer the following questions (pay attention to the JSON fields in the output):

- Which **OS** does the image have? (`.Os`)
- When was it **created**? (`.Created`)
- Which **environment variables** are defined? (`.Config.Env`)

> Tip: For targeted output, use e.g. `docker inspect --format '{{ .Os }}' python:3`.

---

## Exercise 2: Image tagging

We practice working with tags and aliases.

- Download the image `node:latest` using the `pull` command
- Assign an alias with the name `my-node:latest`.

> Hint: An alias is also set with the `tag` command.

- Check which tags the image has locally (see the `.RepoTags` field)
- First remove the alias tag `my-node:latest`.
- Then remove the tag `node:latest` as well.

> Watch the CLI output closely: How do the responses differ when removing them? What is the
> difference between deleting a tag and deleting an image?
