# Lab 02: Docker Images

## Exercise 1: Inspecting images

We list the images already on the machine and then take a closer look at one of them.

- First, list all locally available images.
- Then inspect the image `python:3` in detail using the `inspect` command.

Answer the following questions (pay attention to the JSON fields in the output):

- Which **OS** does the image have? (`.Os`)
- When was it **created**? (`.Created`)
- Which **environment variables** are defined? (`.Config.Env`)

> Tip: `docker inspect --format '{{ .Os }}' python:3` prints just this one field.

---

## Exercise 2: Image tagging

Now for tags and aliases.

- Download the image `node:latest` using the `pull` command
- Give it the alias `my-node:latest`.

> Hint: the `tag` command sets aliases as well.

- Check which tags the image has locally (see the `.RepoTags` field)
- First remove the alias tag `my-node:latest`.
- Then remove the tag `node:latest` as well.

> Watch the CLI output closely: how does it differ between the two removals? What is the
> difference between deleting a tag and deleting an image?
