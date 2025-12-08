# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR_MARIADB = /home/wscherre/data/mariadb
DATA_DIR_WORDPRESS = /home/wscherre/data/wordpress

# Default target, executed when you run `make`
all: build up

# Create data directories and build the Docker images
build:
	@mkdir -p $(DATA_DIR_MARIADB)
	@mkdir -p $(DATA_DIR_WORDPRESS)
	@echo "Building Docker images..."
	docker compose -f $(COMPOSE_FILE) build

# Start the services in the background
up:
	@echo "Starting services..."
	docker compose -f $(COMPOSE_FILE) up -d

# Stop the services
down:
	@echo "Stopping services..."
	docker compose -f $(COMPOSE_FILE) down

# Clean up: stop services and remove volumes
clean: down
	@echo "Cleaning up..."
	@echo "Shutting down dockers..."
	docker compose -f $(COMPOSE_FILE) down -v
	@echo "Pruning volumes..."
	docker system prune -a --volumes -f
	@echo "Removing data directories..."
	sudo rm -rf /home/wscherre/data

# Full clean: clean and remove images
fclean: clean
	@echo "Removing images..."
	docker compose -f $(COMPOSE_FILE) down --rmi all

# Rebuild: clean everything and build again
re: fclean all

.PHONY: all build up down clean fclean re
