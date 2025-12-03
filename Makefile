# ----------------------------------------------
# Auto-detect platform to select compose files
# ----------------------------------------------

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  # Development on macOS
  COMPOSE_FILES = -f docker-compose.yml -f docker-compose.dev.yml
else
  # Production / server (Linux)
  COMPOSE_FILES = -f docker-compose.yml
endif

SHELL = bash

DC = docker compose $(COMPOSE_FILES)

# ----------------------------------------------
# Commands
# ----------------------------------------------

# Start prod
up:
	$(DC) up caddy rais -d

# Start test also
up2:
	$(DC) up rais2 -d

# Stop everything
down:
	$(DC) down

# Stop test
down2:
	$(DC) stop rais2

# Follow logs
logs:
	$(DC) logs -f

# Rebuild and start
rebuild:
	$(DC) up --build

# Show running containers
ps:
	$(DC) ps

# ----------------------------------------------
# Shard generation + sync
# ----------------------------------------------

# Generate shards for main viewer and copy to test viewer
shards:
	python3 path-finder.py
	mkdir -p webroot2/idx
	cp -r webroot/idx/* webroot2/idx/
	echo "Shards generated and copied to webroot2/"
