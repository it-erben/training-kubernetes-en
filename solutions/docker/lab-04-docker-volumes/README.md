# Solution for the Docker Volumes exercise

```shell
docker run -it --rm --mount type=bind,source="${PWD}",target=/tmp/scripts python:3 bash
```
