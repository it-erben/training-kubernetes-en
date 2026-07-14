FROM python:3.11-slim AS builder

WORKDIR /app
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

COPY pyproject.toml README.md /app/
COPY src /app/src

RUN pip install --upgrade pip build \
    && python -m build --wheel --no-isolation


FROM python:3.11-slim

WORKDIR /app
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /app/dist/ /tmp/dist/
RUN pip install /tmp/dist/*.whl && rm -rf /tmp/dist

EXPOSE 8080

CMD ["simple-server"]


