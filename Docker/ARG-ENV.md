# Understanding ARG and ENV in Docker

## Overview

Docker provides two main instructions for handling variables in Dockerfiles: `ARG` and `ENV`. Both are used to inject values, but they serve different purposes and have different scopes.

## ARG: Build-Time Variables

- **Definition:**
  - `ARG` defines a variable that users can pass at build-time to the Docker build process using `--build-arg`.
  - Its value is available only during the image build and **not** in the running container.
- **Syntax:**
  ```dockerfile
  ARG <variable_name>[=<default_value>]
  ```
- **Example:**
  ```dockerfile
  ARG API_KEY_VALUE
  RUN echo "API Key at build: $API_KEY_VALUE"
  ```
- **Usage:**
  - To pass a value: `docker build --build-arg API_KEY_VALUE=12345 .`
  - If not provided, the default (if any) is used.
- **Scope:**
  - Only available during build (in `RUN`, `ENV`, etc. in Dockerfile).
  - Not persisted in the final image (unless copied to `ENV`).

## ENV: Run-Time Environment Variables

- **Definition:**
  - `ENV` sets an environment variable in the image, making it available to containers started from the image.
- **Syntax:**
  ```dockerfile
  ENV <key>=<value>
  ```
- **Example:**
  ```dockerfile
  ENV API_KEY=12345
  CMD ["printenv", "API_KEY"]
  ```
- **Usage:**
  - The variable is available to all processes in the running container.
  - Can be overridden at runtime with `docker run -e API_KEY=67890 ...`.
- **Scope:**
  - Available to all layers after the `ENV` instruction and in the running container.

## ARG and ENV Together

You can use `ARG` to accept a build-time value and then set it as an `ENV` variable for use at runtime:

```dockerfile
ARG API_KEY_VALUE
ENV API_KEY=${API_KEY_VALUE}
```

- Here, `API_KEY_VALUE` is set at build time, and its value is assigned to the `API_KEY` environment variable in the image.
- At runtime, `API_KEY` is available to the container.

## Complete Example

**Dockerfile:**
```dockerfile
FROM alpine:3.18
ARG API_KEY_VALUE
ENV API_KEY=${API_KEY_VALUE}
CMD ["sh", "-c", "echo API_KEY is $API_KEY"]
```

**Build:**
```bash
docker build --build-arg API_KEY_VALUE=supersecret -t arg-env-demo .
```

**Run:**
```bash
docker run --rm arg-env-demo
# Output: API_KEY is supersecret
```

## Key Points
- `ARG` is for build-time only; `ENV` is for runtime.
- `ARG` values are not persisted in the final image unless copied to `ENV`.
- Use `ARG` for secrets or values you don't want in the final image, or to parameterize builds.
- Use `ENV` for configuration needed by the running application.

## References
- [Dockerfile reference: ARG](https://docs.docker.com/engine/reference/builder/#arg)
- [Dockerfile reference: ENV](https://docs.docker.com/engine/reference/builder/#env)
