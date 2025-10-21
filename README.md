# hbgb-rais-caddy

Minimal stack for serving large herbarium images with the  
[**Rodent-Assimilated Image Server (RAIS)**](https://github.com/uoregon-libraries/rais-image-server) — a IIIF-compliant image server from the University of Oregon Libraries —  
fronted by [**Caddy**](https://caddyserver.com/) for clean URLs and optional HTTPS,  
and viewed with [**OpenSeadragon**](https://openseadragon.github.io/) for smooth zooming and panning.

---

## Requirements

- **Docker** and **Docker Compose** (or Podman + podman-compose)  
- Basic network access (port 8080 for local test, 80/443 in production)  
- **Python 3** to generate the `idx` mapping files before starting the stack  

---

## Structure

```
hbgb-rais-caddy/
├── data/
│    └── Delivery/        # JP2 image files for local test (RAIS reads from here)
│                         # In production, files live outside the repo
├── webroot/              # Static files for the viewer
│   ├── index.html        # OpenSeadragon viewer page
│   └── idx/              # JSON index shards (map IDs → image paths)
├── .env.template         # Template for .env (local settings)
├── docker-compose.yml    # Starts RAIS + Caddy
├── Caddyfile             # Caddy config (serves site + proxies /iiif/)
├── path-finder.py        # Script that builds shard index files
├── requirements.txt      # Python dependencies for helper scripts
└── venv/                 # (optional) Local virtual environment, not tracked in git
```

---

## Setup

### 1. Create the environment file
Copy and edit as needed before running the stack:

```
cp .env.template .env
```

Typical local values:
```
DATA_PATH=./
HOST=localhost
```

Production example:
```
DATA_PATH=/
HOST=your.example.org
```

---

### 2. (Optional) Create a Python virtual environment

If you want to isolate the Python tools (recommended):

```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
Deactivate later with:

```
deactivate
```

---

## Generating index shards (required before running the stack)

The viewer looks up each image ID in small JSON “shard” files under `webroot/idx/`.  
Before starting the stack, build those shards from your JP2 image tree:

```
python3 path-finder.py
```

The script:

- Reads `DATA_PATH` from `.env` (defaults to `./`)
- Scans `data/Delivery/` (or the mounted image path)
- Groups images by the first seven characters of their ID (e.g. `GB-0517…`)
- Creates one JSON file per group inside `webroot/idx/`

---

## Running the stack (local test)

1. **Start the containers**

   ```bash
   docker compose up -d
   ```
   or
   ```bash
   podman-compose up -d
   ```

   - Caddy listens on **http://localhost:8080**  
   - RAIS runs internally on port **12415** (not exposed directly)

2. **Open the viewer**

   ```
   http://localhost:8080/GB-0500017
   ```
   Replace `GB-0500017` with the filename (without `.jp2`) of any image.

---

## How the RAIS IIIF server works

RAIS follows the [IIIF Image API 2.1](https://iiif.io/api/image/2.1/).  
Caddy proxies all `/iiif/...` requests to RAIS, keeping everything under one clean origin.

Example URLs through Caddy:

```
http://localhost:8080/iiif/2023/01/23/CP1_20230123_BATCH_0001/GB-0500017.jp2/info.json
http://localhost:8080/iiif/2023/01/23/CP1_20230123_BATCH_0001/GB-0500017.jp2/full/2000,/0/default.jpg
```

---

## How OpenSeadragon works

[OpenSeadragon](https://openseadragon.github.io/) loads only the visible parts of an image as small tiles,  
so you can pan and zoom smoothly without downloading the entire file.  
It uses RAIS’s `info.json` endpoint to know how to request tiles at the right resolution.

See a live OpenSeadragon IIIF demo:  
[https://openseadragon.github.io/examples/tilesource-iiif/](https://openseadragon.github.io/examples/tilesource-iiif/)

---

## Moving to production (later)

1. Change `:8080` in the Caddyfile to your domain:
   ```
   your.example.org {
       ...
   }
   ```
2. In `docker-compose.yml`, map ports 80 and 443 instead of 8080:
   ```yaml
   ports:
     - "80:80"
     - "443:443"
   ```
3. Run as root (or via systemd).  
   Caddy will automatically obtain and renew a **Let’s Encrypt** certificate.
4. Update `.env`:
   ```
   DATA_PATH=/srv/iiif/
   HOST=your.example.org
   ```

Then open  
`https://your.example.org/GB-0526335`  
for a production-ready IIIF viewer.
