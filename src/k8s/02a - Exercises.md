### Exercise 1: Compare Docker Containers vs. Virtual Machines

**Instruction:**
List at least three fundamental differences between Docker containers and virtual machines (VMs) in terms of isolation, resource usage, and boot time. Provide a brief explanation for each.

**Answer:**

1. **Isolation Level**

    * **Docker Containers:** Provide process‐level isolation by sharing the host OS kernel; each container runs as an isolated process namespace on the same OS.
    * **VMs:** Offer full machine‐level isolation; each VM has its own guest OS running atop a hypervisor, so the entire kernel is separate from the host.
    * **Explanation:** Containers share the host’s kernel, so they cannot customize kernel state, but VMs can—hence VMs are stronger isolation boundaries at the cost of extra overhead.

2. **Resource Usage**

    * **Docker Containers:** Lightweight because they do not require a separate OS per instance. They reuse the host’s kernel and only package the app’s dependencies and runtime libraries.
    * **VMs:** Resource‐heavy since each VM includes a full OS—every VM boots its own kernel, consumes RAM/CPU for the entire guest OS, and potentially multiple OS‐level daemons.
    * **Explanation:** Containers spin up much smaller footprints (often tens or hundreds of MB), whereas VMs can easily be multiple GB for a single guest OS image.

3. **Boot Time**

    * **Docker Containers:** Typically start in seconds (or less), since they simply initialize a few namespaces and cgroups around an already‐running kernel.
    * **VMs:** Take minutes to boot, because they must initialize a full virtual hardware stack and boot the guest OS as if it were a physical machine.
    * **Explanation:** Containerized processes can begin almost instantly, but a VM simulates hardware, loads a kernel, initializes services, etc., which is inherently slower.

---

### Exercise 2: Pulling and Inspecting an Image

**Instruction:**

1. Write the exact `docker` CLI command to pull the official Nginx image with the `latest` tag from Docker Hub.
2. After pulling, show the command to list all local images and then the command to inspect the newly pulled Nginx image (to see its metadata in raw JSON).

**Answer:**

1. **Pull the Nginx Image**

   ```bash
   docker pull nginx:latest
   ```

    * This downloads the `nginx` repository with the tag `latest`. If no tag is specified, Docker defaults to `:latest`.

2. **List All Local Images**

   ```bash
   docker images
   ```

    * Outputs a table showing all images currently stored locally (Repository, Tag, Image ID, Created, Size).

3. **Inspect the `nginx:latest` Image**

   ```bash
   docker inspect nginx:latest
   ```

    * Dumps a JSON‐formatted document containing detailed metadata (entrypoint, environment, layers, created timestamp, author, etc.).

---

### Exercise 3: Running and Managing a Container

**Instruction:**

1. Using the Nginx image you pulled in Exercise 2, write a command to start an Nginx container in detached mode, name it `webserver`, and map host port 8080 to container port 80.
2. Then write the command to list only running containers.
3. Finally, write the commands to stop and remove the `webserver` container.

**Answer:**

1. **Run Nginx in Detached Mode with Port Mapping**

   ```bash
   docker run -d \
     --name webserver \
     -p 8080:80 \
     nginx:latest
   ```

    * `-d` → Detached (background).
    * `--name webserver` → Container is assigned the name `webserver`.
    * `-p 8080:80` → Host’s port 8080 maps to container’s port 80.

2. **List Only Running Containers**

   ```bash
   docker ps
   ```

    * By default, `docker ps` shows only “Up” containers. You should see a line with `webserver` and ports `0.0.0.0:8080->80/tcp`.

3. **Stop the `webserver` Container**

   ```bash
   docker stop webserver
   ```

    * Sends a SIGTERM (and SIGKILL after 10 seconds if not stopped) to gracefully stop `webserver`.

4. **Remove the `webserver` Container**

   ```bash
   docker rm webserver
   ```

    * Deletes the stopped container. If it hadn’t been stopped first, you could force remove with `docker rm -f webserver`, but the recommended approach is to stop, then remove.

---

### Exercise 4: Creating a Simple Dockerfile

**Instruction:**
Create a `Dockerfile` for a minimal “Hello, World” Node.js application. The application source code is in `index.js` (which listens on port 3000 and returns “Hello, World” when accessed). Your `Dockerfile` should:

1. Use `node:18-alpine` as the base image.
2. Set `/usr/src/app` as the working directory.
3. Copy `package.json` and `package-lock.json`, run `npm install --production`.
4. Copy the remainder of the application (including `index.js`).
5. Expose port 3000.
6. Set the default command to `node index.js`.

Provide the complete contents of the `Dockerfile`.

**Answer:**

```dockerfile
# 1. Use official Node 18 runtime on Alpine
FROM node:18-alpine

# 2. Create/app directory in container
WORKDIR /usr/src/app

# 3. Copy package manifests and install dependencies
COPY package*.json ./
RUN npm install --production

# 4. Copy application source code into working directory
COPY . .

# 5. Expose application port
EXPOSE 3000

# 6. Default command to run the app
CMD ["node", "index.js"]
```

* **Explanation of each instruction:**

    1. `FROM node:18-alpine` → small Node.js base for minimal footprint.
    2. `WORKDIR /usr/src/app` → creates and sets that directory as current.
    3. `COPY package*.json ./` → pulls in `package.json` and `package-lock.json`.
    4. `RUN npm install --production` → installs only “dependencies” (no devDependencies).
    5. `COPY . .` → copies `index.js` and any other files into the image.
    6. `EXPOSE 3000` → documents that the container listens on 3000.
    7. `CMD ["node", "index.js"]` → when the container runs, it executes this command.

---

### Exercise 5: Multi‐Stage Build for a Go Application

**Instruction:**
Write a multi‐stage `Dockerfile` that compiles a Go application into a static binary and then packages it into a minimal final image. Assume your Go source files (with `main.go` and its dependencies) reside in the build context root. The final image should be based on `alpine:latest` and include only the compiled binary named `app`. Use `/root/` as the working directory in the final stage and expose port 8080. Provide the complete `Dockerfile`.

**Answer:**

```dockerfile
###############
# Stage 1: Build the Go binary
###############
FROM golang:1.20-alpine AS builder

# Set working directory inside the builder
WORKDIR /app

# Copy Go modules manifests and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code and build the binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

###############
# Stage 2: Create the minimal final image
###############
FROM alpine:latest

# (Optional) Install certificates if the app makes HTTPS calls
RUN apk add --no-cache ca-certificates

# Set working directory inside final image
WORKDIR /root/

# Copy compiled binary from builder stage
COPY --from=builder /app/app .

# Expose the port that the Go app listens on
EXPOSE 8080

# Default entrypoint to run the binary
ENTRYPOINT ["./app"]
```

* **Explanation:**

    1. **Builder stage (`golang:1.20-alpine`)**

        * Downloads modules (`go mod download`).
        * Copies source, compiles a static binary (`CGO_ENABLED=0`).
    2. **Final stage (`alpine:latest`)**

        * Installs only root CA certificates if needed.
        * Copies the `app` binary from the builder stage.
        * Has no Go toolchain, so the final image is very small (only the binary + needed libs).
        * Exposes port 8080 and runs `./app`.

---

### Exercise 6: Volumes and Data Persistence

**Instruction:**

1. Write the `docker` commands to create a named volume called `my_data_vol`.
2. Run a Redis container (using `redis:latest`) named `redis-server` with that volume mounted to `/data` inside the container. (Redis writes its data to `/data`.)
3. Demonstrate how you would inspect the volume to see its details.
4. Finally, show how to remove the `my_data_vol` volume, assuming no container is using it.

**Answer:**

1. **Create a Named Volume**

   ```bash
   docker volume create my_data_vol
   ```

    * Creates a Docker-managed volume named `my_data_vol`.

2. **Run Redis with the Volume Mounted**

   ```bash
   docker run -d \
     --name redis-server \
     -v my_data_vol:/data \
     redis:latest
   ```

    * `-v my_data_vol:/data` → Mounts `my_data_vol` at `/data` inside the container so Redis can persist data there.
    * `-d` → Runs detached in background.

3. **Inspect the Volume**

   ```bash
   docker volume inspect my_data_vol
   ```

    * Outputs JSON showing `Mountpoint` (the host path), driver, labels, usage count, etc.

4. **Remove the Volume**

   ```bash
   docker volume rm my_data_vol
   ```

    * Deletes `my_data_vol` only if no container is currently using it. If it’s still in use (e.g., `redis-server` is running), you must stop/remove the container first.

---

### Exercise 7: Networking—User‐Defined Bridge Network

**Instruction:**

1. Create a new user‐defined bridge network named `app-net`.
2. Run a PostgreSQL container (image `postgres:13`) named `db-server` connected to `app-net` with a volume `pg_data` mounted at `/var/lib/postgresql/data` (create that volume first).
3. Run a custom web application container named `web-app` (assume image is `mydbapp:latest`) connected to `app-net`, mapping host port 5000 to container port 5000. The web app should use environment variables `DB_HOST=db-server`, `DB_PORT=5432`.
4. Explain briefly how the `web-app` container can connect to the PostgreSQL container by name.

**Answer:**

1. **Create the Bridge Network**

   ```bash
   docker network create app-net
   ```

    * This makes a user‐defined network where containers can automatically resolve each other by name.

2. **Create the `pg_data` Volume**

   ```bash
   docker volume create pg_data
   ```

3. **Run the PostgreSQL Container**

   ```bash
   docker run -d \
     --name db-server \
     --network app-net \
     -v pg_data:/var/lib/postgresql/data \
     -e POSTGRES_PASSWORD=mysecretpassword \
     postgres:13
   ```

    * `-e POSTGRES_PASSWORD=...` sets the database password.
    * `--network app-net` attaches `db-server` to `app-net`.
    * `-v pg_data:/var/lib/postgresql/data` → persists DB data in the named volume.

4. **Run the Web Application Container**

   ```bash
   docker run -d \
     --name web-app \
     --network app-net \
     -p 5000:5000 \
     -e DB_HOST=db-server \
     -e DB_PORT=5432 \
     mydbapp:latest
   ```

    * `--network app-net` → Both `web-app` and `db-server` share the `app-net` network.
    * `DB_HOST=db-server` → Inside `web-app`, the hostname `db-server` resolves to the PostgreSQL container’s IP.
    * `-p 5000:5000` → Exposes the web app on host port 5000.

5. **How `web-app` Connects to PostgreSQL by Name**

    * In a user‐defined bridge network (`app-net`), Docker’s embedded DNS server automatically registers container names. Thus, inside `web-app`, connecting to `db-server:5432` will reach the PostgreSQL container on that network. You do not need the container’s IP—just use the service name as `DB_HOST`.

---

### Exercise 8: Docker Compose for a Two‐Service Stack

**Instruction:**
Given a project directory with this structure:

```
my-app/
├── docker-compose.yml
├── web/
│   ├── Dockerfile
│   └── index.js
└── redis_data/
```

Write a complete `docker-compose.yml` (version `3.9`) to define two services:

* **web**:

    * build from `./web` (use the `Dockerfile` there)
    * image tag should be `myuser/my-web-app:latest`
    * container name `web-app`
    * map host port 8080 to container port 3000
    * set two environment variables: `REDIS_HOST=redis` and `REDIS_PORT=6379`
    * depends on the Redis service

* **redis**:

    * use official image `redis:6-alpine`
    * container name `redis`
    * mount a named volume `redis-data` to `/data`

Also, define the named volume `redis-data` at the bottom of the file.

**Answer:**

```yaml
version: "3.9"

services:
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: myuser/my-web-app:latest
    container_name: web-app
    ports:
      - "8080:3000"
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - redis

  redis:
    image: redis:6-alpine
    container_name: redis
    volumes:
      - redis-data:/data

volumes:
  redis-data:
    driver: local
```

* **Explanation of key fields:**

    * `version: "3.9"` → Use the modern Compose file format.
    * `web.build.context: ./web` → Builds the `web` service from `my-app/web/Dockerfile`.
    * `image: myuser/my-web-app:latest` → Tags the built image appropriately.
    * `ports: "8080:3000"` → Host 8080 → container 3000.
    * `depends_on: [redis]` → Ensures Redis starts before the web service.
    * `redis.volumes: [redis-data:/data]` → Uses `redis-data` to persist Redis data under `/data`.
    * Volume definition at bottom ensures `redis-data` is created using the `local` driver.

---

### Exercise 9: Pruning Unused Resources

**Instruction:**
Your Docker host has accumulated the following unused artifacts:

* Several stopped containers
* Dangling images (intermediate layers not referenced by any tagged image)
* Unused named volumes
* User‐defined networks that aren’t connected to any container

List the `docker` commands you would run (in sequence) to remove all of these:

1. Remove all stopped containers.
2. Remove dangling images only (not all unused images).
3. Remove all unused volumes that are not referenced by any container.
4. Remove all unused networks not used by any container.
5. Finally, run a single “system‐wide” prune that asks for confirmation and also prunes everything not in use (containers, networks, dangling images, build cache) but leaves volumes alone.

**Answer:**

1. **Remove All Stopped Containers**

   ```bash
   docker container prune
   ```

    * Interactive: prompts “Are you sure you want to continue?” → `y`. Removes every container in `Exited` state.

2. **Remove Dangling Images Only**

   ```bash
   docker image prune
   ```

    * By default, deletes only “dangling” (unreferenced) images. Again, prompts for confirmation.

3. **Remove Unused Volumes**

   ```bash
   docker volume prune
   ```

    * Removes volumes not referenced by any container. Prompts for confirmation.

4. **Remove Unused Networks**

   ```bash
   docker network prune
   ```

    * Deletes user‐defined networks that are not used by at least one container. Also prompts.

5. **System‐Wide Prune (Excluding Volumes)**

   ```bash
   docker system prune
   ```

    * Interactively removes all stopped containers, dangling and unused images, unused networks, and build cache, but does not remove volumes (unless you add `--volumes`).

---

### Exercise 10: Hiding Sensitive Data in Image Builds

**Instruction:**
You need to clone a private Git repository (`https://github.com/yourorg/secret-repo.git`) during the image build, using a build‐time secret stored in a local file `gh_token.txt`. The goal is to avoid embedding the GitHub token into any image layer. Using Docker BuildKit’s `--mount=type=secret` feature, write a `Dockerfile` snippet (just the relevant portion) that:

1. Specifies the BuildKit syntax directive.
2. Uses `ubuntu:20.04` as the base.
3. Installs `git`.
4. During one `RUN` step, mounts the secret `id=gh_token` from `gh_token.txt`, clones the private repo into `/tmp/app`, and then removes any credentials (if applicable).
5. Copies only `/tmp/app` contents into `/opt/app` in a final stage so that no secret remains in the final image.

Also specify the `docker build` command you would run to supply the secret.

**Answer:**

```dockerfile
# syntax=docker/dockerfile:1.4
###############
# Stage 1: Clone private repo using BuildKit secret
###############
FROM ubuntu:20.04 AS builder

# Install git in a single step
RUN apt-get update && apt-get install -y git

# Clone the private repo using the secret token; secret is mounted at /run/secrets/gh_token
RUN --mount=type=secret,id=gh_token \
    GIT_TOKEN=$(cat /run/secrets/gh_token) && \
    git clone https://$GIT_TOKEN@github.com/yourorg/secret-repo.git /tmp/app && \
    rm -rf /tmp/app/.git

###############
# Stage 2: Final image without any secret
###############
FROM ubuntu:20.04

# Copy only the application source from the builder stage
COPY --from=builder /tmp/app /opt/app

WORKDIR /opt/app
# (Install any runtime dependencies and set up ENTRYPOINT/CMD as needed)
```

**Build Command:**

```bash
export DOCKER_BUILDKIT=1
docker build \
  --secret id=gh_token,src=gh_token.txt \
  -t my-private-app:latest \
  .
```

* **Explanation of key parts:**

    1. `# syntax=docker/dockerfile:1.4` → Enables BuildKit features (especially `--mount=type=secret`).
    2. `RUN --mount=type=secret,id=gh_token \` → During that `RUN`, `/run/secrets/gh_token` is an ephemeral file containing the token.
    3. `git clone https://$GIT_TOKEN@github.com/yourorg/secret-repo.git /tmp/app && rm -rf /tmp/app/.git` → Clones privately, then deletes the `.git` folder so the secret isn’t embedded.
    4. **Final stage** copies only the code from `/tmp/app` into the runtime image so no trace of the token remains in the final layers.
    5. In the `docker build` command, `--secret id=gh_token,src=gh_token.txt` provides BuildKit with the file to mount.

