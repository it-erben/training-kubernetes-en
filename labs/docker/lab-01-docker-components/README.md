# Lab 01: Docker Basics

## Exercise 1: First container – Hello World

Start a container to check whether Docker works on your machine:

```shell
docker run hello-world
```

You should see a greeting message from Docker.  
That means the Docker Engine and the Docker Daemon are up and running.

---

## Exercise 2: Python in a container

Start an interactive container with Python:

```shell
docker run -it --rm python:3 python
```

At the Python prompt, check today's date:

```python
from datetime import date
print(date.today())
```

The output should look roughly like this (depending on today's date):

```text
2025-09-21
```

Exit the Python session with `exit()` or `CTRL+D`.

---

## Exercise 3: Docker Client

Sometimes the Docker CLI does not behave the way you expect.  
When that happens, you want to know exactly what is installed:

```shell
docker version
```

Find out and write down:

- Which version of **Docker Desktop** is installed?
- Which version of the **Docker Engine** is installed?

Hint: You will find this information in the `Client` and `Server` sections.

---

## Exercise 4: Docker Daemon

The following command gives you information about the Docker daemon:

```shell
docker info
```

Answer the following questions:

- Which **default runtime** does the daemon use?
- Which **runtimes** are available in total?
- Which **operating system** does the host have?
- How many **CPUs** are available?
- How much **memory** is available?

> Tip: Scroll through the output and look specifically for these fields.
