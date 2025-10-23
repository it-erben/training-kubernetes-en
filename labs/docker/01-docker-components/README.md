# Docker Basics

## Exercise 1: First Container – Hello World

Run a container to verify that **Docker is working** on your machine:

```shell
docker run hello-world
```

You should see a **greeting message** from Docker.
This confirms that the **Docker Engine** and **Docker Daemon** are operational.

-----

## Exercise 2: Python in a Container

Start an **interactive container** running Python:

```shell
docker run -it --rm python:3 python
```

At the Python prompt, check the current date:

```python
from datetime import date
print(date.today())
```

The output should look similar to this (depending on the current date):

```
2025-09-21
```

Exit the Python session using **`exit()`** or **`CTRL+D`**.

-----

## Exercise 3: Docker Client

Sometimes the Docker CLI doesn't behave as expected.
It's important to know how to display information about your installation:

```shell
docker version
```

Determine and record:

- What version of **Docker Desktop** is installed?
- What version of the **Docker Engine** is installed?

👉 **Hint:** You'll find these details in the **`Client`** and **`Server`** sections of the output.

-----

## Exercise 4: Docker Daemon

Use the following command to retrieve information about the Docker Daemon:

```shell
docker info
```

Answer the following questions:

- What is the Daemon's **Default Runtime**?
- How many **Runtimes** are available in total?
- What is the host's **Operating System**?
- How many **CPUs** are available?
- How much **Memory** is available?

> **Tip:** Scroll through the output and look specifically for these fields.
