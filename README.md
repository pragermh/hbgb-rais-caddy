# hbgb-rais-caddy
Minimal stack for serving large herbarium images with the [**Rodent-Assimilated Image Server (RAIS)**](https://github.com/uoregon-libraries/rais-image-server) — a IIIF-compliant image server from the University of Oregon Libraries —  fronted by [**Caddy**](https://caddyserver.com/) for clean URLs and optional HTTPS, and viewed with [**OpenSeadragon**](https://openseadragon.github.io/) for smooth zooming and panning.

This setup includes:
- One primary RAIS instance (`rais`) served under the main vhost
- One secondary RAIS instance (`rais2`) intended as a dedicated test environment, with its own vhost and separate static webroot
- Separate production and development Caddyfiles
- Local docker-compose overrides (`docker-compose.dev.yml`) for easy local testing
- A Makefile for starting/stopping the stack efficiently

## Requirements
- Docker + Docker Compose (or Podman alternatives)  
- Python 3 (for generating image index shards)  
- Basic network access (8080/8081 locally, 80/443 in production)

## Structure
```

hbgb-rais-caddy/
├── data/
│ └── Delivery/            # JP2 image files (Local only. In production, image files live outside the repo)
├── webroot/               # Static site for the main RAIS instance
│ ├── index.html
│ └── idx/
├── webroot2/              # Static site for the test RAIS instance
│ ├── index.html
│ └── idx/
├── Caddyfile              # Production Caddy config (two vhosts)
├── Caddyfile.dev          # Local dev config (two HTTP ports :80/:81)
├── docker-compose.yml     # Base stack (rais, rais2, caddy)
├── docker-compose.dev.yml # Dev override
├── Makefile               # Helper commands
├── .env.template          # Template env settings
├── path-finder.py         # Script that builds shard index files
├── requirements.txt       # Python dependencies for helper scripts
└── venv/                  # (optional) Local virtual environment, not tracked in git
```

## Environment Setup

### 1. Create `.env`

Copy:

    cp .env.template .env

Example local values:

    DATA_PATH=./
    HOST=localhost
    HOST2=localhost

Example production:

    DATA_PATH=/
    HOST=your.main.host
    HOST2=your.test.host

These values are used by both RAIS and Caddy.

## Python Virtual Environment (optional)

    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

Deactivate:

    deactivate

## Generating Index Shards (required)

Generate shards for the main viewer:

    python3 path-finder.py

The script:
- Reads `DATA_PATH` from `.env`
- Scans `data/Delivery/`
- Groups image IDs
- Writes output to `webroot/idx/`

### Using shards in the test environment

Copy the main shards:

    cp -r webroot/idx webroot2/

Or use:

    make shards

This regenerates and syncs shards into `webroot2/idx/`.

## Running the Stack (Makefile)

Start main stack:

    make up

Start test environment:

    make up2

Stop everything:

    make down

Stop only test:

    make down2

Logs, rebuild, and status commands are also available (`make logs`, `make rebuild`, `make ps`).

## Local Development

Using `docker-compose.dev.yml`, Caddy exposes:

- http://localhost:8080 → main stack
- http://localhost:8081 → test stack

Example:

    http://localhost:8080/GB-0500017

Both viewers serve static files and reverse-proxy `/iiif` to their respective RAIS backend.

## Production Deployment

Caddy uses hostnames from `.env` via variables in the Caddyfile:

- {$HOST}   → main viewer (`/srv`)
- {$HOST2}  → test viewer (`/srv2`)

Both virtual hosts run inside one Caddy instance and share ports 80/443.

### Running the stack

    make up
    make up2

Example URLs:

    https://$HOST/<IMAGE-ID>
    https://$HOST2/<IMAGE-ID>

### Port configuration

Caddy listens on ports 80/443 inside the container.

If you run Docker/Podman in *rootless mode*, it cannot bind privileged ports.
In that case you may need to forward public ports 80→8080 and 443→8443 on the host,
and map those in docker-compose:

    ports:
      - "8080:80"
      - "8443:443"

This still allows automatic HTTPS, as long as public traffic on 80/443 reaches
container ports 80/443 via the forwarding.

If you run Docker/Podman as root (or use a system-level service), you can instead
bind ports directly:

    ports:
      - "80:80"
      - "443:443"

### Health checks

Both vhosts expose:

    https://$HOST/health
    https://$HOST2/health

Returns: `ok`.

### Logs and Troubleshooting

All services:

    make logs

Individual containers:

    docker logs caddy -f
    docker logs rais -f
    docker logs rais2 -f

Status:

    make ps

### Updating the stack

Pull images:

    docker compose pull

Restart:

    make up
    make up2

Rebuild:

    make rebuild

## How the RAIS IIIF server works

RAIS follows the [IIIF Image API 2.1](https://iiif.io/api/image/2.1/).  
Caddy proxies all `/iiif/...` requests to RAIS, keeping everything under one clean origin.

Example URLs through Caddy:

```
http://localhost:8080/iiif/2023/01/23/CP1_20230123_BATCH_0001/GB-0500017.jp2/info.json
http://localhost:8080/iiif/2023/01/23/CP1_20230123_BATCH_0001/GB-0500017.jp2/full/2000,/0/default.jpg
```

## How OpenSeadragon works

[OpenSeadragon](https://openseadragon.github.io/) loads only the visible parts of an image as small tiles,  
so you can pan and zoom smoothly without downloading the entire file.  
It uses RAIS’s `info.json` endpoint to know how to request tiles at the right resolution.

See a live OpenSeadragon IIIF demo:  
[https://openseadragon.github.io/examples/tilesource-iiif/](https://openseadragon.github.io/examples/tilesource-iiif/)
