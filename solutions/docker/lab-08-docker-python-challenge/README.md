# Solution: Multistage Dockerfile

- The Dockerfile covers all steps from the challenge (builder + runtime).
- Build: `docker build -t simple-server .`
- Run: `docker run -p 8080:8080 simple-server`
- Expected result: the container starts the `simple-server` binary from the built wheel on port 8080.
