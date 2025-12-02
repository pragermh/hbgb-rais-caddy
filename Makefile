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

# Start everything (dev: both stacks, prod: full stack)
up:
	$(DC) up -d

# Start only "webroot" stack (rais + Caddy)
up1:
	$(DC) up caddy rais

# Start only "webroot2" stack (rais2 + Caddy)
up2:
	$(DC) up caddy rais2

# Stop everything
down:
	$(DC) down

# Stop only rais
down1:
	$(DC) stop rais

# Stop only rais2
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
