# Sample solution for the final exercise

## Dockerfile

```Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY app.js .
ENV PORT=3000
EXPOSE 3000
CMD ["node", "app.js"]
```

## Walkthrough

```bash
# Build the image
docker build -t final-app .

# Host directory for the bind mount
mkdir -p content && echo "hello" > content/file.txt

# Test the container locally
docker run -d --name final-app -p 3000:3000 -e PORT=3000 final-app
curl http://localhost:3000

# Restart with a bind mount (Step 3)
docker rm -f final-app
docker run -d --name final-app -p 3000:3000 -e PORT=3000 \
  -v "$(pwd)/content:/tmp/content" final-app
curl http://localhost:3000

# Custom network + second container (Step 4)
docker network create final-net
docker rm -f final-app
docker run -d --name final-app --network final-net -e PORT=3000 final-app
docker run -it --rm --network final-net alpine sh -c "apk add --no-cache curl && curl -s http://final-app:3000"

# Clean up
docker rm -f final-app
docker network rm final-net
docker rmi final-app
```
