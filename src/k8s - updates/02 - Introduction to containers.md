## 1. Introduction to Docker

### 1.1 What Is Docker?

* **Definition**: Docker is an open-source platform for packaging, distributing, and running applications in lightweight, isolated containers.
* **Container vs. Traditional Deployment**:

    * A **container** packages an application’s code along with its runtime, libraries, and environment variables into a single unit.
    * Each container runs as an isolated process on the host OS kernel.
    * This isolates dependencies and configuration so that “it works on my machine” reliably becomes “it works everywhere.”

### 1.2 Why Use Containers Instead of Virtual Machines?

* **Virtual Machines (VMs)** run a full guest operating system on top of a hypervisor.

    * Each VM includes its own kernel and OS libraries.
    * Boot times are measured in minutes; resource usage is higher.
    * Example: Running two VMs on a laptop might require 2 GB RAM each just for operating systems, plus CPU overhead.

* **Docker Containers** share the host machine’s kernel.

    * They only package the application and its dependencies.
    * Startup times are in seconds; resource usage is minimal.
    * Example: You can spin up multiple Node.js containers (all on the same kernel) that each take only a few tens of megabytes of memory.

| Feature        | Docker Containers                        | Virtual Machines                        |
| -------------- | ---------------------------------------- | --------------------------------------- |
| Isolation      | Process-level (shares OS kernel)         | Full machine-level (separate OS per VM) |
| Boot Time      | Seconds                                  | Minutes                                 |
| Resource Usage | Low (no separate OS)                     | High (each VM includes full OS)         |
| Portability    | Very high (runs on any host with Docker) | Medium (depends on hypervisor)          |
| Startup Speed  | Fast                                     | Slower                                  |

**Key takeaway**: Containers provide OS-level virtualization, resulting in faster startups and lower overhead. VMs provide hardware-level virtualization and are heavier but offer stronger “full system” isolation.

---

## 2. Docker Architecture

Docker employs a **client-server architecture**. Understanding each piece clarifies how Docker commands from a terminal translate into running workloads on a host.

### 2.1 Docker Client (`docker` CLI)

* The CLI tool (`docker`) is what users interact with to run commands (e.g., `docker run`, `docker build`, `docker pull`).
* It communicates with the Docker daemon through a REST API over a UNIX socket (or TCP).
* You can run the client and daemon on the same machine or have the client connect to a remote daemon (for centralized management).

### 2.2 Docker Daemon (`dockerd`)

* The daemon runs as a background service on the host.
* Responsibilities:

    * Build images
    * Manage images, networks, and volumes
    * Create, start, stop, and delete containers
    * Serve API requests from Docker clients
* On a Linux host, you typically start the daemon with `sudo systemctl start docker` (or equivalent).

### 2.3 Docker Objects

Docker revolves around a few primary objects that the daemon manages:

1. **Images**: Read-only templates from which containers are instantiated.
2. **Containers**: Writable, running instances of images (isolated processes).
3. **Volumes**: Persistent storage decoupled from container lifetimes.
4. **Networks**: Abstracted layer-3 networks that let containers communicate.

### 2.4 Docker Registry

* A registry is a repository for storing and sharing images.
* **Docker Hub** is the default public registry, but companies often run private registries (e.g., AWS ECR, GCR, Harbor).
* When you `docker pull ubuntu:20.04`, the client first checks locally; if the image isn’t present, it fetches layers from the registry.
* When you push a custom image (e.g., `myrepo/myapp:1.0`), Docker uploads its layers to whichever registry you have logged into.

---

## 3. Core Concepts & Components

### 3.1 Docker Engine

* Consists of the CLI (`docker`), the daemon (`dockerd`), and the REST API that glues them together.
* It is the runtime piece that actually launches containers on a host.

### 3.2 Images vs. Containers

**Images**

* A versioned, immutable file system snapshot containing application binaries, libraries, and metadata (like environment variables, default command, exposed ports).
* Built in *layers*; each instruction in a Dockerfile (e.g., `RUN apt-get update`, `COPY . .`) creates a new layer.
* Shared via a registry—no need to rebuild from scratch if you already have an image’s layers locally.

**Containers**

* Instances of images that “run.”
* Writable layer on top of the image’s read-only layers (any changes happen in this layer).
* Each container gets its own namespaces for process IDs, file system, and networking.
* Lifecycle commands:

    * `docker run` → create + start a container
    * `docker ps` / `docker ps -a` → list running or all containers
    * `docker stop` → gracefully stop (SIGTERM then SIGKILL)
    * `docker start` → restart a stopped container
    * `docker rm` → delete a stopped container

### 3.3 Dockerfile

* A simple text file with declarative steps (directives) that tell Docker how to build an image.
* Common directives (in order of typical appearance):

    1. `FROM` – Base image (e.g., `node:18-alpine`, `python:3.11-slim`)
    2. `LABEL` – Metadata (author, version)
    3. `WORKDIR` – Sets working directory for subsequent steps
    4. `COPY` / `ADD` – Copy files from host into image
    5. `RUN` – Run commands (typically installing dependencies)
    6. `ENV` – Set environment variables inside the image
    7. `EXPOSE` – Document which ports the container will listen on (does not publish ports)
    8. `CMD` – Default command to run in a container (can be overridden at runtime)
    9. `ENTRYPOINT` – Configures the container as a fixed executable, optionally complemented by `CMD` for arguments
    10. `USER` – Switch to a specific user (for least-privilege)
    11. `VOLUME` – Declares mount points for volumes
    12. `ARG` – Build-time variable

#### Example Dockerfile for a Node.js App

```dockerfile
# 1. Base image: Official Node.js on Alpine (small footprint)
FROM node:18-alpine 

# 2. Metadata
LABEL maintainer="Jane Doe <jane@example.com>"

# 3. Set working directory (created if it doesn’t exist)
WORKDIR /usr/src/app

# 4. Copy and install dependencies first (leveraging layer caching)
COPY package*.json ./
RUN npm install --production

# 5. Copy application source
COPY . .

# 6. Document the port
EXPOSE 3000

# 7. Environment variable
ENV NODE_ENV=production

# 8. Default command
CMD ["node", "index.js"]
```

* **Build**:

  ```bash
  docker build -t my-node-app:1.0 .
  ```
* **Tag for registry**:

  ```bash
  docker tag my-node-app:1.0 mydockerhubusername/my-node-app:1.0
  ```
* **Push to Docker Hub**:

  ```bash
  docker push mydockerhubusername/my-node-app:1.0
  ```

### 3.4 Docker Compose

* A tool to define and manage multi-container applications using a `docker-compose.yml` file.
* Instead of manually running several `docker run` commands, you describe all services, networks, and volumes in one place.
* You can bring everything up with `docker-compose up` and tear it down with `docker-compose down`.

**Basic `docker-compose.yml` Example**

```yaml
version: '3.9'

services:
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: mydockerhubusername/my-web-app:latest
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

* **Start**: `docker-compose up -d` builds (if needed) and launches all services
* **Stop & Remove**: `docker-compose down` (add `-v` to also remove volumes)

---

## 4. Managing Images & Containers

Once you grasp Docker’s objects, these are the go-to commands for everyday work.

### 4.1 Working with Images

* **Pull an image** (download from registry):

  ```bash
  docker pull nginx:latest
  ```
* **List local images**:

  ```bash
  docker images
  # OUTPUT:
  # REPOSITORY        TAG       IMAGE ID       CREATED        SIZE
  # nginx             latest    a66f...        2 days ago     133MB
  # ubuntu            20.04     f643...        3 weeks ago    73MB
  ```
* **Remove an image**:

  ```bash
  docker rmi nginx:latest
  # If image is in use by any container, add --force to force removal
  docker rmi -f nginx:latest
  ```

**Versioning/Tagging Strategy**

* Avoid using only `:latest`. Always tag with meaningful versions (SemVer: `1.2.3`, date-based: `2025.05.31`, or a Git SHA).
* Example CI/CD pipeline snippet:

  ```bash
  VERSION=1.2.3
  GIT_SHA=$(git rev-parse --short HEAD)
  docker build -t myrepo/myapp:$VERSION -t myrepo/myapp:$GIT_SHA .
  docker push myrepo/myapp:$VERSION
  docker push myrepo/myapp:$GIT_SHA
  ```

### 4.2 Working with Containers

* **Run a container** (foreground):

  ```bash
  docker run nginx:latest
  # Logs appear in your terminal; CTRL+C to stop
  ```
* **Run a container in detached mode** (background) with port mapping and a custom name:

  ```bash
  docker run -d \
    --name my-nginx \
    -p 8080:80 \
    nginx:latest
  # Access via http://localhost:8080
  ```
* **List running containers**:

  ```bash
  docker ps
  # OUTPUT:
  # CONTAINER ID   IMAGE         COMMAND                  CREATED       STATUS       PORTS                 NAMES
  # c3d2a7b8e0f1   nginx:latest  "/docker-entrypoint.…"   5 mins ago    Up 5 mins    0.0.0.0:8080->80/tcp  my-nginx
  ```
* **List all containers (including stopped)**:

  ```bash
  docker ps -a
  ```
* **Stop a running container**:

  ```bash
  docker stop my-nginx
  # By default, waits 10 seconds before SIGKILL; override with -t <seconds>
  docker stop -t 30 my-nginx
  ```
* **Start a stopped container**:

  ```bash
  docker start my-nginx
  ```
* **Remove a container** (only if stopped):

  ```bash
  docker rm my-nginx
  # Or force-remove (stopping it if needed):
  docker rm -f my-nginx
  ```
* **Inspect container details** (returns JSON with network/IP, mounts, env vars):

  ```bash
  docker inspect my-nginx
  ```
* **Extract specific field via Go template** (e.g., IP Address):

  ```bash
  docker inspect \
    --format='{{ .NetworkSettings.IPAddress }}' my-nginx
  ```
* **View container logs**:

  ```bash
  docker logs my-nginx
  # Follow logs in real time:
  docker logs -f my-nginx
  # Only last 50 lines:
  docker logs --tail 50 my-nginx
  ```
* **Execute an interactive shell inside a container**:

  ```bash
  docker exec -it my-nginx /bin/bash
  # If Bash is unavailable, try /bin/sh:
  docker exec -it my-nginx /bin/sh
  ```

---

## 5. Data Management: Volumes & Bind Mounts

By default, any changes made inside a container’s filesystem disappear once the container is removed. To persist or share data, use:

### 5.1 Named Volumes

* **Create a named volume** (Docker manages location):

  ```bash
  docker volume create my_data_vol
  ```
* **Run a container with that volume**:

  ```bash
  docker run -d \
    --name redis-server \
    -v my_data_vol:/data \
    redis:latest
  # Redis will write its data to /data, which persists beyond container lifetime
  ```
* **List volumes**:

  ```bash
  docker volume ls
  ```
* **Inspect a volume** (to see mountpoint on host):

  ```bash
  docker volume inspect my_data_vol
  ```
* **Remove a volume** (only if not in use):

  ```bash
  docker volume rm my_data_vol
  # Force remove (danger: data loss if still mounted):
  docker volume rm -f my_data_vol
  ```

### 5.2 Bind Mounts

* Bind mounts map a directory on the host to a directory in the container. Useful for local development (code changes on host immediately reflect in the container).
* **Run a container with a bind mount (read-only)**:

  ```bash
  docker run -d \
    --name web-server \
    -p 8000:80 \
    -v /home/user/website:/usr/share/nginx/html:ro \
    nginx:latest
  ```

    * Host path `/home/user/website` → container `/usr/share/nginx/html` (nginx doc root)
    * `:ro` (read-only); omit or use `:rw` (read-write) for two-way sync.

---

## 6. Networking in Docker

Docker automatically creates three default networks on installation:

1. **bridge** (default for standalone containers)
2. **host** (container shares host’s network stack; Linux only)
3. **none** (no networking for container)

### 6.1 Default (bridge) Network

* If you `docker run` without specifying `--network`, the container attaches to the default `bridge` network.
* Containers on the same user-defined bridge can reach each other by IP or by container name (DNS). On the default bridge, name resolution is not automatic unless you explicitly enable it.

### 6.2 Host Network

* On Linux, `--network host` means the container uses the host’s network namespace. No port mapping needed; container ports are the host’s ports.
* On macOS/Windows, `host` behaves like `bridge`.

### 6.3 none Network

* `--network none` disables networking entirely.
* Useful for maximum isolation (e.g., a data processing container that only writes to a volume and never needs external access).

### 6.4 Creating & Using a User-Defined Bridge Network

1. **Create a network**:

   ```bash
   docker network create app-net
   ```

    * Result: a new bridge network named `app-net`.
2. **Verify networks**:

   ```bash
   docker network ls
   # OUTPUT:
   # NETWORK ID     NAME      DRIVER    SCOPE
   # 5c7e8c1c760a   bridge    bridge    local
   # 90f2b7f8f9c3   app-net   bridge    local
   # ecbf8a7810e4   host      host      local
   # 1b6a4b8e36f2   none      null      local
   ```
3. **Run containers on that network**:

   ```bash
   docker run -d \
     --name db-server \
     --network app-net \
     postgres:13
   ```

   ```bash
   docker run -d \
     --name web-app \
     --network app-net \
     -p 5000:5000 \
     my-flask-image:latest
   ```

    * Within `app-net`, `web-app` can reach `db-server` simply by using hostname `db-server:5432`.
4. **Inspect the network** (see attached containers, IP addresses):

   ```bash
   docker network inspect app-net
   ```

---

## 7. Building Custom Images (Deep Dive)

A strong understanding of Dockerfiles and build strategies is crucial for producing small, maintainable, and secure images.

### 7.1 Basic Dockerfile Directives Recap

1. **FROM**: Base image (e.g., `alpine`, `ubuntu:20.04`, `node:18-alpine`).
2. **LABEL**: Metadata (e.g., `LABEL maintainer="..."`).
3. **WORKDIR**: Sets `/path` inside image; creates it if needed.
4. **COPY** / **ADD**: Copy files from host into the image.

    * `ADD` can unzip tarballs or fetch remote URLs, but `COPY` is preferred for simplicity.
5. **RUN**: Execute commands (e.g., `RUN apt-get update && apt-get install -y python3`). Each `RUN` creates a new layer.
6. **ENV**: Define persistent environment variables.
7. **EXPOSE**: Informational: declares which ports the container listens on.
8. **CMD**: Default command (exec form recommended: array of strings).
9. **ENTRYPOINT**: Fixes the container to behave like an executable. Combined with `CMD` to supply default arguments.
10. **USER**: Switch to a non-root user for least-privilege.
11. **VOLUME**: Declare mount points (actual volumes attached at runtime).
12. **ARG**: Build-time variables passed with `docker build --build-arg`.

### 7.2 Building an Image

* **In the directory with your Dockerfile**, run:

  ```bash
  docker build -t my-app:1.0 .
  ```

* **Flags**:

    * `-t name:tag` → assign name & tag to built image
    * `.` → context is current directory (all files under `.` get sent to Docker daemon; Docker uses only the ones referenced via `COPY`/`ADD`)

* **Layer Caching**:

    * Docker caches each layer. If a step in the Dockerfile hasn’t changed (and its inputs are identical), Docker reuses the cached layer.
    * **Best practice**: Copy or install dependencies first, then copy application code. If code changes but dependencies remain the same, Docker only re-runs the final COPY + later steps, not the install steps.

### 7.3 Tagging and Pushing

1. **Tag an existing image**:

   ```bash
   docker tag my-app:1.0 myrepo/my-app:1.0
   ```
2. **Log in to a registry (e.g., Docker Hub)**:

   ```bash
   docker login
   ```
3. **Push the image**:

   ```bash
   docker push myrepo/my-app:1.0
   ```
4. **Pull on another host**:

   ```bash
   docker pull myrepo/my-app:1.0
   ```

### 7.4 Multi-Stage Builds (Minimizing Final Image Size)

* Purpose: Separate “build” dependencies (compilers, SDKs) from “runtime” files so that build artifacts appear in the final image without including the entire build toolchain.
* **Example: Go Application**

  ```dockerfile
  # Stage 1: Build Go binary
  FROM golang:1.20-alpine AS builder

  WORKDIR /app
  COPY go.mod go.sum ./
  RUN go mod download
  COPY . . 
  RUN go build -o myapp .

  # Stage 2: Create minimal final image
  FROM alpine:latest

  # If your Go app needs TLS, install certs
  RUN apk add --no-cache ca-certificates

  WORKDIR /root/
  COPY --from=builder /app/myapp .

  EXPOSE 8080
  ENTRYPOINT ["./myapp"]
  ```

    * **How It Works**:

        1. **builder stage**: uses `golang:1.20-alpine`, compiles the code, creates `/app/myapp`.
        2. **final stage**: `alpine:latest` is very small. Only the compiled binary (and optionally certs) are copied over.
    * **Result**: Final image might be < 10 MB (just a static binary + minimal libs), whereas if you used only `golang:1.20-alpine`, it would be \~ 300 MB.

### 7.5 Leveraging BuildKit for Secrets at Build-Time

* BuildKit (default in recent Docker releases) allows ephemeral mounting of secrets so that they never appear in image layers.
* **Example Dockerfile Using BuildKit Secrets**

  ```dockerfile
  # syntax=docker/dockerfile:1.4
  FROM ubuntu:20.04

  # Install a client that needs credentials (e.g., MySQL client)
  RUN apt-get update && apt-get install -y mysql-client curl

  # Mount secret at /run/secrets/db_pass during this RUN only
  RUN --mount=type=secret,id=db_pass \
      export DB_PASS=$(cat /run/secrets/db_pass) && \
      mysql --host=db.example.com --user=admin --password="$DB_PASS" \
            --execute="USE mydb; SELECT VERSION();" \
      && echo "Verified DB connectivity"

  COPY . /opt/app
  WORKDIR /opt/app
  RUN make build

  CMD ["./start-app"]
  ```

    * **Build command**:

      ```bash
      export DOCKER_BUILDKIT=1
      docker build \
        --secret id=db_pass,src=/path/to/db_password.txt \
        -t my-db-client-image:latest .
      ```
    * **Why safe**: The secret is only available in-memory during that single `RUN` step. It does not persist in any layer once the step completes.

---

## 8. Using Docker Registries

### 8.1 Public vs. Private Registries

* **Docker Hub**: Default public registry. Any user can pull public images.
* **Private Registry**: Set up on-premise or in cloud (e.g., AWS ECR, Google Container Registry, Azure Container Registry).
* **Self-Hosted**: You can deploy “Docker Registry” open-source server on your own infrastructure.

### 8.2 Authenticating & Pushing Images

1. **Log in** (Docker Hub or custom registry):

   ```bash
   docker login                    # for Docker Hub
   docker login my-registry.local  # for private registry
   ```

    * Prompts for username/password or token.
    * Credentials saved under `~/.docker/config.json`.
2. **Tag for registry**:

   ```bash
   docker tag my-app:1.0 myusername/my-app:1.0
   # Or for a custom registry:
   docker tag my-app:1.0 my-registry.local:5000/my-app:1.0
   ```
3. **Push**:

   ```bash
   docker push myusername/my-app:1.0
   ```
4. **Pull** on another host:

   ```bash
   docker pull myusername/my-app:1.0
   ```

---

## 9. Docker Compose (Multi-Container Orchestration)

Compose is a YAML-based tool that simplifies running multiple coordinated containers.

### 9.1 Why Use Compose?

* Single file describes all services in an application (app server, database, cache, message broker, etc.).
* `docker-compose up` brings everything up in correct order (based on dependencies).
* `docker-compose down` stops and removes all components (containers, networks, default volumes).
* Easy environment variable injection, scaling replicas, and volume mounting for multiple services.

### 9.2 Installing Docker Compose

* On modern Docker Desktop (macOS/Windows), Compose is built in as either `docker-compose` or `docker compose`.
* On Linux, you may need to download a binary or use distribution packages:

  ```bash
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version  # should print v2.20.2 or similar
  ```

### 9.3 Sample `docker-compose.yml`

```yaml
version: '3.8'

services:
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    image: myusername/my-web-app:latest
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

* **Key fields**:

    * `build.context` & `dockerfile`: Where to find source and Dockerfile.
    * `image`: name/tag to use. Useful if you want to push this image afterward.
    * `container_name`: overrides automatically generated container name.
    * `ports`: list of `<host_port>:<container_port>` mappings.
    * `environment`: environment variables within container.
    * `depends_on`: simple startup ordering (does not wait for “healthy” status, only for container to be running).
    * `volumes`: named volumes for persistence.

* **Commands**:

    * Start everything (build if needed):

      ```bash
      docker-compose up -d
      ```
    * List running services:

      ```bash
      docker-compose ps
      ```
    * Stream logs from all services:

      ```bash
      docker-compose logs -f
      ```
    * Stop & remove:

      ```bash
      docker-compose down
      # Add -v to also remove volumes:
      docker-compose down -v
      ```
    * Scale a service (only for non-Swarm mode; Compose v2 supporting swarm requires `deploy`):

      ```bash
      docker-compose up -d --scale web=3
      ```

        * You might need a load balancer in front if your code does not do internal balancing.

---

## 10. Daily Container Administration

Even a small Docker deployment requires consistent monitoring and housekeeping. Below are routine tasks to integrate into daily operations.

### 10.1 Log Collection & Rotation

#### 10.1.1 Viewing Container Logs

* **Basic log retrieval** (stdout + stderr):

  ```bash
  docker logs my-app-container
  ```
* **Follow logs in real time**:

  ```bash
  docker logs -f my-app-container
  ```
* **Limit to last N lines**:

  ```bash
  docker logs --tail 100 my-app-container
  ```
* **Example**: To first see 50 most recent lines and then follow new lines:

  ```bash
  docker logs --tail 50 -f my-app-container
  ```

> **Note**: If you change the log driver from the default `json-file`, then `docker logs` no longer works; you must query whichever backend you configured (e.g., Fluentd, GELF).

#### 10.1.2 Configuring Log Rotation for JSON-File Driver

By default, Docker stores container logs under `/var/lib/docker/containers/<container-id>/<container-id>-json.log`. If left unbounded, these files grow indefinitely.

1. **Edit (or create) `/etc/docker/daemon.json`** on the host:

   ```jsonc
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "5"
     }
   }
   ```

    * `"max-size": "10m"`: Maximum size of each log file is 10 MB.
    * `"max-file": "5"`: Rotate up to 5 old files (e.g., `.1`, `.2`, …).

2. **Restart Docker daemon** to apply changes:

   ```bash
   sudo systemctl restart docker
   # or
   sudo service docker restart
   ```

3. **Verify on a running container**:

   ```bash
   docker inspect --format='{{ .HostConfig.LogConfig.Type }}' my-app-container
   # Expect: json-file

   docker inspect \
     --format='{{ range $k, $v := .HostConfig.LogConfig.Config }}{{$k}}={{$v}} {{end }}' \
     my-app-container
   # Expect: max-size=10m max-file=5
   ```

> **Note**: These settings apply only to newly started containers after the daemon restarts. Existing containers keep their previous log-driver configuration until replaced or manually updated.

#### 10.1.3 Shipping Logs to a Central Aggregator

For multiple hosts or production setups, centralizing logs (ELK, Splunk, Graylog, etc.) is best practice. You configure each container’s log driver to send logs over the network:

* **GELF (Graylog) Example**:

  ```bash
  docker run -d \
    --name my-app-container \
    --log-driver=gelf \
    --log-opt gelf-address=udp://log-collector.example.com:12201 \
    my-app-image:latest
  ```

    * Docker sends logs in Graylog Extended Log Format to your GELF collector via UDP.

* **Fluentd Example**:

  ```bash
  docker run -d \
    --name my-app-container \
    --log-driver=fluentd \
    --log-opt fluentd-address=fluentd-host:24224 \
    --log-opt tag="docker.myapp" \
    my-app-image:latest
  ```

    * Logs flow to Fluentd on TCP port 24224 with a tag of `docker.myapp`.

> **Reminder**: Once you switch to a non-default log driver, you must query your aggregator to see container logs (e.g., `fluentd` or `gelf`)—`docker logs` no longer works.

---

### 10.2 Gathering Performance Metrics

Keeping an eye on CPU, memory, network, and disk usage helps catch problems early.

#### 10.2.1 `docker stats` for Live Monitoring

* **Run `docker stats`** (real-time summary for all running containers):

  ```bash
  docker stats
  ```
* **Per-container statistics**:

  ```bash
  docker stats my-app-container
  ```
* **Sample output columns**:

  ```
  CONTAINER ID   NAME              CPU %     MEM USAGE / LIMIT   MEM %     NET I/O       BLOCK I/O   PIDS
  f3f1d2c7c1b2   my-app-container  3.18%     150MiB / 1GiB       14.64%    1.2MB / 0.5MB  100kB / 20kB  12
  ```
* **One-shot, formatted output** (good for scripts):

  ```bash
  docker stats --no-stream --format "{{.Name}}: CPU {{.CPUPerc}}, Mem {{.MemPerc}}"
  ```

#### 10.2.2 Integrating cAdvisor or Prometheus

For continuous, long-term monitoring, run a container that exposes metrics in Prometheus format:

* **cAdvisor Docker Example**:

  ```bash
  docker run -d \
    --name cadvisor \
    --volume=/:/rootfs:ro \
    --volume=/var/run:/var/run:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --publish=8080:8080 \
    gcr.io/cadvisor/cadvisor:latest
  ```

    * cAdvisor reads container metadata and usage stats, exposing them at `http://localhost:8080/metrics`.
    * Point a Prometheus server to scrape `http://<host-ip>:8080/metrics` on a regular schedule.
    * Use Grafana (or another visualization tool) to build dashboards.

#### 10.2.3 Docker Events for Lifecycle Alerts

Docker emits events on lifecycle changes (container start, stop, die, kill, etc.). You can listen and integrate into alerting or automation:

* **Listen to all events**:

  ```bash
  docker events
  ```

  Streams events indefinitely until you cancel (CTRL+C).

* **Filter for a specific event** (e.g., container “die”):

  ```bash
  docker events --filter 'event=die'
  ```

  You might pipe this to a script that sends an email or triggers a remediation when a critical container dies unexpectedly.

---

### 10.3 Configuring Restart Policies

For high availability, automatically restart containers when they fail or when the Docker daemon restarts.

#### 10.3.1 Built-In Restart Policies

* `no` (default): Do not restart automatically.
* `on-failure[:max-retries]`: Restart only if the container exits with a nonzero exit code; optionally limit retries.
* `always`: Always restart if the container stops for any reason (even on daemon restart).
* `unless-stopped`: Like `always`, but do not restart if the container was explicitly stopped by the user.

#### 10.3.2 Applying Restart Policy When Starting a Container

```bash
docker run -d \
  --name my-critical-service \
  --restart unless-stopped \
  my-critical-image:latest
```

* If `my-critical-service` crashes (exit code ≠ 0) or the Docker daemon reboots, Docker brings it back up automatically.

**Example (on-failure with limited retries)**

```bash
docker run -d \
  --name flaky-worker \
  --restart on-failure:5 \
  my-worker-image
```

* If `flaky-worker` exits with a non-zero code, Docker tries up to 5 restarts, then gives up.

#### 10.3.3 Updating Restart Policy on a Running Container

```bash
docker update \
  --restart always \
  my-app-container
```

* The `docker update` command can change a container’s restart policy, CPU and memory limits, etc., without recreating it.
* If you switch from `no` to `always`, the next time the container stops (even because Docker restarted), it automatically comes back.

#### 10.3.4 Best Practices

1. **Long-Running Services**: Use `unless-stopped` for databases, web servers, and any service you always expect to run unless you explicitly shut it down.
2. **Batch or Short-Lived Jobs**: Use `on-failure` with a retry limit so failed jobs don’t spin in a restart loop forever.
3. **Monitor Restart Loops**: If a container continuously crashes (restarts repeatedly), it can overwhelm the host. Combine with a health check to prevent looping on an unhealthy state.

### 10.4 Health Checks (Optional Enhancement)

* You can embed a **`HEALTHCHECK`** in your Dockerfile so Docker knows whether your application inside the container is actually ready/functional.
* **Example (Nginx)**

  ```dockerfile
  FROM nginx:latest

  # Check every 30s; timeout after 5s; start grace period 5s; retry 3 times
  HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

  # … rest of Dockerfile …
  ```
* Docker will mark the container’s status as “healthy” or “unhealthy.”
* **Check status**:

  ```bash
  docker ps
  # In the STATUS column, see “Up X minutes (healthy)” or “(unhealthy)”
  ```
* If a container becomes unhealthy, you can use `docker inspect --format='{{ .State.Health.Status }}' my-container` in a script to alert or restart it.

---

## 11. Hiding Sensitive Data in Image Builds

Building images often requires access to private repositories, API keys, or certificates. If you bake secrets into an image (via `ENV`, `ADD`, or `COPY`), they remain in image layers forever. These guidelines explain how to keep secrets out of final images.

### 11.1 Never Hard-Code Secrets in a Dockerfile

❌ **Bad Pattern**

```dockerfile
FROM ubuntu:20.04
ENV AWS_SECRET_KEY=ABCD1234SECRET
RUN apt-get update && apt-get install -y python3
COPY . /app
CMD ["python3", "/app/app.py"]
```

* **Problem**: `AWS_SECRET_KEY` is baked into the image’s metadata layers. Anyone who pulls the image can inspect layers or run `docker history` to find it.

### 11.2 Use Build-Time Arguments (`ARG`) Carefully

* `ARG` variables exist only during build. Unless you explicitly assign them to an `ENV`, they do not persist in the final image’s environment metadata.
* **Example**: Cloning a private Git repository at build time.

  ```dockerfile
  # Dockerfile
  FROM python:3.11-slim

  ARG MY_SECRET
  RUN git clone https://username:${MY_SECRET}@github.com/org/private-repo.git /tmp/app && \
      rm -rf /tmp/app/.git

  WORKDIR /tmp/app
  RUN pip install -r requirements.txt

  CMD ["python3", "main.py"]
  ```

    * **Build command**:

      ```bash
      docker build --build-arg MY_SECRET=$(cat ~/secret.txt) -t my-private-app:latest .
      ```
* **Caveat**: Even though `ENV` is not set, the secret appears in the layer’s metadata if you “inspect” intermediate layers. Intermediate layers can be viewed via `docker history` or if someone extracts the image’s tarball.
* **Mitigation**: Delete any file containing the secret (or remove credentials) in the same `RUN` line after use. For ultimate isolation, move secret-using steps to a prior stage and then do a multi-stage copy (see next section).

### 11.3 Multi-Stage Builds to Keep Secrets Out of Final Image

* By splitting your Dockerfile into multiple stages, you can confine secret-dependent commands to a “builder” stage that is never included in the final image.
* **Example**: Cloning a private repo with a secret, then building the final image without any Git or credentials:

  ```dockerfile
  # Stage 1: Download private repo with secret
  FROM alpine/git AS downloader

  ARG MY_SECRET
  RUN git clone https://username:${MY_SECRET}@github.com/org/private-repo.git /tmp/app-source

  # Stage 2: Build runtime image (no secrets)
  FROM python:3.11-slim

  WORKDIR /opt/app
  COPY --from=downloader /tmp/app-source /opt/app
  RUN pip install -r requirements.txt

  CMD ["python3", "main.py"]
  ```

    * Build with:

      ```bash
      docker build --build-arg MY_SECRET=$(cat ~/secret.txt) -t myapp:latest .
      ```
    * **Why It Works**:

        * Stage 1 uses `MY_SECRET` to do a `git clone`. That stage’s layers (containing the Git URL with the secret in history) remain accessible only as an intermediate, untagged image.
        * Stage 2 starts from a fresh base, copying only the files from `/tmp/app-source` (the checked-out code). No secret remains.

### 11.4 BuildKit `--mount=type=secret` for True Ephemeral Secrets

* If you enable BuildKit (e.g., `export DOCKER_BUILDKIT=1`), you can mount secrets at build time without leaving traces in layers.
* **Example Dockerfile with BuildKit Secret**

  ```dockerfile
  # syntax=docker/dockerfile:1.4
  FROM ubuntu:20.04

  RUN apt-get update && apt-get install -y mysql-client curl

  # Mount secret at /run/secrets/db_pass only during this RUN
  RUN --mount=type=secret,id=db_pass \
      export DB_PASS=$(cat /run/secrets/db_pass) && \
      mysql --host=db.example.com --user=admin --password="$DB_PASS" \
            --execute="USE mydb; SELECT VERSION();" \
      && echo "Database connectivity verified"

  COPY . /opt/app
  WORKDIR /opt/app
  RUN make build

  CMD ["./start-app"]
  ```
* **Build command**:

  ```bash
  export DOCKER_BUILDKIT=1
  docker build --secret id=db_pass,src=/path/to/db_password.txt -t my-db-client-image:latest .
  ```
* **Why safe**: The secret is only available in-memory during that specific `RUN` step. It never persists to disk or into any image layer. After the step finishes, the secret is destroyed.

### 11.5 Injecting Secrets at Runtime (Container Start)

* If your application needs secrets (DB credentials, API tokens) at runtime, do **not** bake them into the image. Instead, supply them when you run the container.

**Approach A: `.env` File**

1. Create an `.env` file (never commit to Git):

   ```text
   DB_HOST=prod-db.example.com
   DB_USER=admin
   DB_PASS=SuperSecretPassword
   ```
2. Start your container with:

   ```bash
   docker run -d \
     --env-file .env \
     --name my-app \
     my-app-image:latest
   ```
3. Inside the container, the environment variables `DB_HOST`, `DB_USER`, and `DB_PASS` will be set. Your application code should read from `process.env.DB_PASS` (Node.js) or equivalent.

**Approach B: Docker Secrets (Swarm Mode)**

* In Docker Swarm, you can store secrets in memory, encrypt them, and only grant services access.

1. **Create a secret**:

   ```bash
   echo "SuperSecretPassword" | docker secret create db_pass -
   ```
2. **Reference the secret in `docker-compose.yml`** (Swarm version 3.1+):

   ```yaml
   version: "3.8"

   services:
     web:
       image: my-app-image:latest
       secrets:
         - db_pass
       environment:
         - DB_USER=admin
         # DB_PASS is not in env; your code must read from /run/secrets/db_pass
       configs:
         - source: app_config
           target: /etc/app/config.yaml

   secrets:
     db_pass:
       external: true
       name: db_pass
   ```
3. **Deploy to Swarm**:

   ```bash
   docker stack deploy -c docker-compose.yml my_stack
   ```
4. Inside the container, `/run/secrets/db_pass` contains the secret. Read from that file in your code.

> **Best Practices Summary**:
>
> 1. **Never** hard-code secrets in Dockerfiles (`ENV`, `ADD`, `COPY`).
> 2. Use multi-stage builds to confine secrets to a build stage that does not get tagged or shared.
> 3. Use BuildKit’s ephemeral `--mount=type=secret` when possible (Docker v18.09+).
> 4. At runtime, inject secrets via `--env-file` or Docker Secrets (Swarm/Kubernetes), not baked into images.
> 5. Keep `.env` files and secret materials out of Git (`.gitignore`).

---

## 12. Cleaning Up & Maintenance Best Practices

Over time, Docker hosts can accumulate unused images, stopped containers, orphaned volumes, and unused networks. Regular cleanup is essential.

### 12.1 Pruning Unused Resources

1. **Remove stopped containers**:

   ```bash
   docker container prune
   # Prompts for confirmation, then deletes all containers in “Exited” status
   ```
2. **Remove dangling images** (untagged, intermediate layers):

   ```bash
   docker image prune
   ```
3. **Remove all unused images** (dangling or unreferenced)—use with caution:

   ```bash
   docker image prune -a
   ```
4. **Remove unused volumes**:

   ```bash
   docker volume prune
   ```
5. **Remove unused networks**:

   ```bash
   docker network prune
   ```
6. **System-wide aggressive prune** (all stopped containers, dangling images, unused networks, optional volumes):

   ```bash
   docker system prune
   # Add --volumes to also remove all unused volumes
   docker system prune -a --volumes
   ```

   > **Warning**: The `-a` flag with `--volumes` is destructive, removing everything not currently in use.

### 12.2 Tagging & Version Strategy (Recap)

* Avoid always using `:latest`. Tag images semantically (e.g., `v2.0.1`, `2025.05.31`).
* In CI/CD, tag images with Git SHAs or build numbers to ensure traceability.
* Example pipeline snippet:

  ```bash
  VERSION=1.2.3
  GIT_SHA=$(git rev-parse --short HEAD)
  docker build -t myrepo/myapp:$VERSION -t myrepo/myapp:$GIT_SHA .
  docker push myrepo/myapp:$VERSION
  docker push myrepo/myapp:$GIT_SHA
  ```

### 12.3 Security Considerations

1. **Least Privilege**

    * Don’t run containers as `root`. Use `USER nonrootuser` in your Dockerfile whenever possible.
2. **Keep Base Images Updated**

    * Rebuild images regularly to pick up security patches (e.g., `node:18-alpine`, `ubuntu:20.04`) and rebuild with the latest patch level.
3. **Scan Images for Vulnerabilities**

    * Integrate tools like **Trivy**, **Clair**, or **Snyk** in your pipeline to scan for known CVEs.
    * Example:

      ```bash
      trivy image myrepo/myapp:1.0
      ```
4. **Limit Resource Usage**

    * Constrain CPU and memory to prevent a container from monopolizing host resources:

      ```bash
      docker run -d \
        --name resource_limited \
        --memory="512m" \
        --cpus="1.0" \
        my-app-image:latest
      ```
5. **Use User-Defined Networks**

    * Isolate containers onto networks so they only communicate with other services they need.
    * Example:

      ```bash
      docker network create secure-net
      docker run -d --network secure-net --name db-server postgres:13
      docker run -d --network secure-net --name web-app -p 5000:5000 my-web-image
      ```
6. **Secrets Management**

    * Use Docker Secrets in Swarm/Kubernetes instead of environment variables for production.
    * Avoid committing secret files to version control. Use vaults (HashiCorp Vault, AWS Secrets Manager) where possible.

---

## 13. Summary of Key Docker Commands

Below is a concise reference table. Replace placeholders (`<container>`, `<image>`) with your actual names.

| Task                            | Command Example                                             | Notes                                                                 |
| ------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------- |
| **Pull an image**               | `docker pull ubuntu:20.04`                                  | Fetches image from Docker Hub or specified registry                   |
| **List local images**           | `docker images`                                             | Shows repository, tag, image ID, creation time, size                  |
| **Remove an image**             | `docker rmi my-image:1.0`                                   | Deletes image if no containers depend on it                           |
| **Run a container (detached)**  | `docker run -d --name my-container -p 8080:80 nginx:latest` | Runs Nginx in background, maps host port 8080 → container port 80     |
| **List running containers**     | `docker ps`                                                 | Shows only containers in “Up” state                                   |
| **List all containers**         | `docker ps -a`                                              | Shows running, stopped, and exited containers                         |
| **Stop a container**            | `docker stop my-container`                                  | Sends SIGTERM, waits 10s, then SIGKILL                                |
| **Start a container**           | `docker start my-container`                                 | Restarts a stopped container                                          |
| **Remove a container**          | `docker rm my-container`                                    | Deletes a stopped container                                           |
| **Inspect container**           | `docker inspect my-container`                               | Outputs JSON with network, mounts, environment, etc.                  |
| **View logs**                   | `docker logs -f my-container`                               | Streams real-time STDOUT/STDERR of container                          |
| **Exec into container**         | `docker exec -it my-container /bin/bash`                    | Opens interactive shell (requires that shell to exist inside)         |
| **Create a volume**             | `docker volume create my-vol`                               | Creates a named Docker-managed volume                                 |
| **Run container with volume**   | `docker run -d -v my-vol:/data redis:latest`                | Mounts named volume at `/data` inside Redis                           |
| **Remove a volume**             | `docker volume rm my-vol`                                   | Deletes volume if unused                                              |
| **Create a network**            | `docker network create app-net`                             | Creates a user-defined bridge network                                 |
| **Run container on network**    | `docker run -d --name db --network app-net postgres:13`     | Attaches PostgreSQL container to `app-net`                            |
| **Inspect a network**           | `docker network inspect app-net`                            | Details containers, IPs, driver info                                  |
| **Build image from Dockerfile** | `docker build -t my-app:1.0 .`                              | Builds image from Dockerfile in current directory                     |
| **Tag an image**                | `docker tag my-app:1.0 myrepo/my-app:1.0`                   | Names image for pushing to registry                                   |
| **Push image to registry**      | `docker push myrepo/my-app:1.0`                             | Uploads image to Docker Hub or specified registry                     |
| **Compose up (detached)**       | `docker-compose up -d`                                      | Build (if needed) & start services in `docker-compose.yml`            |
| **Compose down**                | `docker-compose down`                                       | Stops & removes containers, networks, and default volumes             |
| **Prune system (aggressive)**   | `docker system prune -a --volumes`                          | Removes all unused images, containers, networks, volumes (be careful) |

---

## 14. Further Reading & Independent Study

To deepen your understanding, consult the following resources and explore topics beyond what’s covered here:

* **Official Docker Documentation**
  [https://docs.docker.com](https://docs.docker.com)

    * Topics: Swarm, Kubernetes integration, advanced networking, storage drivers, security scanning

* **Docker Engine API Reference**
  Provides detailed REST API endpoints if you plan to automate Docker beyond the CLI.
  [https://docs.docker.com/engine/api/latest/](https://docs.docker.com/engine/api/latest/)

* **Docker Best Practices** (Nginx blog, official tutorials, and GitHub examples)

    * Focus on layering, caching, minimal base images, and health checks.

* **Trivy, Clair, or Snyk Scanners**
  Integrate vulnerability scanning into your CI/CD pipeline to catch common CVEs early.
  Examples:

  ```bash
  trivy image myrepo/myapp:latest
  clairctl analyze myrepo/myapp:latest
  ```

* **Prometheus & Grafana**

    * Set up a small Prometheus server to scrape cAdvisor metrics.
    * Build Grafana dashboards to visualize CPU, memory, network usage per container.

* **Kubernetes Intro**
  Docker is often an entry point to container orchestration. Once you grasp Docker basics, look into Kubernetes (`kubectl`, `kind`, `minikube`) to learn how pods, deployments, services, and ingresses work.

* **Docker Security Benchmarks**
  Tools like **Docker Bench for Security** can audit your host against the CIS Docker Benchmark.

  ```bash
  docker run --net host --pid host --userns host --cap-add audit_control \
    --label docker_bench_security \
    docker/docker-bench-security
  ```

---

### Final Thoughts for Independent Learning

1. **Hands-On Practice**

    * Spin up containers for popular databases (MySQL, PostgreSQL, Redis, MongoDB). Practice configuring volumes, environment variables, and networks.
    * Build a small web application in your language of choice, containerize it, and run it alongside a database container.

2. **Iterate on Dockerfiles**

    * Write a Dockerfile, build an image, inspect its size (`docker images`), then optimize by reordering instructions or switching to Alpine-based images.

3. **Explore Compose & Multi-Container Setups**

    * Create a `docker-compose.yml` that spins up 3 replicas of a web server plus a load balancer (e.g., HAProxy or Nginx) in front. Observe how scaling works.

4. **Automate Builds**

    * Hook up a simple GitHub Actions workflow: on every push to `main`, build and push your Docker image to Docker Hub.

5. **Learn to Debug**

    * Practice troubleshooting containers that fail immediately (e.g., show the error via `docker logs`). Learn how to add a `ENTRYPOINT` or `CMD` of `/bin/sh` or `/bin/bash` to get an interactive session when you suspect the container is failing on startup.

6. **Stay Updated**

    * Docker changes frequently—new CLI flags, new Compose features, improvements to BuildKit, new container security best practices. Bookmark the release notes: [https://docs.docker.com/engine/release-notes/](https://docs.docker.com/engine/release-notes/)

