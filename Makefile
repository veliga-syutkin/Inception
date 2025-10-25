# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vsyutkin <vsyutkin@student.42mulhouse.f    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/09/09 04:36:33 by vsyutkin          #+#    #+#              #
#    Updated: 2025/10/25 12:53:50 by vsyutkin         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Makefile for managing the Inception Docker project.
# 
# Targets:
#   all      : Default target. Runs 'up'.
#   up       : Builds and starts the Docker containers defined in srcs/docker-compose.yml in detached mode.
#   down     : Stops and removes the containers defined in srcs/docker-compose.yml.
#   re       : Restarts the containers by running 'down' followed by 'up'.
#   clean    : Stops and removes containers, then prunes all unused Docker data including volumes.
#
# Variables:
#   NAME     : Project name (inception).

NAME=inception
DATA_DIR=/home/vsyutkin/data

all: up

up: create_dirs
	docker-compose --env-file ./secrets/.env -f srcs/docker-compose.yml up -d --build

create_dirs:
	@echo "Creating data directories if they don't exist..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@echo "Data directories ready."

down:
	docker-compose -f srcs/docker-compose.yml down

fclean:
	docker-compose -f srcs/docker-compose.yml down -v
	@echo "*** Cleaning data directories (requires sudo) ***"
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@if [ -n "$$(docker volume ls -qf dangling=true)" ]; then \
		docker volume rm $$(docker volume ls -qf dangling=true); \
	fi
	@if [ -n "$$(docker network ls -qf dangling=true)" ]; then \
		docker network rm $$(docker network ls -qf dangling=true); \
	fi

re: fclean up

# Reinitialize the whole stack (destroys volumes)
reinit:
	@echo "*** Reinitializing stack: this will remove mariadb and wordpress volumes (data loss) ***"
	docker-compose -f srcs/docker-compose.yml down -v
	@echo "*** Cleaning data directories (requires sudo) ***"
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	make create_dirs
	docker-compose --env-file ./secrets/.env -f srcs/docker-compose.yml up -d --build

clean: down
	docker system prune -af --volumes

logs: 
	docker logs inception_mariadb
	docker logs inception_wordpress
	docker logs inception_nginx

# Connect to MariaDB using environment variables from .env
db:
	@echo "Connecting to MariaDB..."
	@docker exec -it inception_mariadb mysql -u$$(grep MYSQL_USER ./secrets/.env | cut -d= -f2) -p$$(grep MYSQL_PASSWORD ./secrets/.env | cut -d= -f2) $$(grep MYSQL_DATABASE ./secrets/.env | cut -d= -f2)

# Connect as root to MariaDB
db-root:
	@echo "Connecting to MariaDB as root..."
	@docker exec -it inception_mariadb mysql -uroot -p"$$(grep MYSQL_ROOT_PASSWORD ./secrets/.env | cut -d= -f2)"

################################################################################ #
# 	CUSTOM 

# Verify presence of env-file
ifneq ("$(wildcard ./secrets/.env)","") # wildcard = check if file exists
else
	$(error "Error: .env file not found in ./secrets/. Aborting...")
endif

git_push: git_add git_status git_commit
	git push

git_add:
	git add . 

git_commit:
	@read -p "Please enter your commit message: " msg; \
	git commit -m "$$msg"

git_status:
	git status

.PHONY: git_push reinit all up down fclean re clean logs db db-root git_add git_commit git_status