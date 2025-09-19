# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: vsyutkin <vsyutkin@student.42mulhouse.f    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/09/09 04:36:33 by vsyutkin          #+#    #+#              #
#    Updated: 2025/09/19 14:12:38 by vsyutkin         ###   ########.fr        #
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

all: up

up:
	docker-compose --env-file ./secrets/.env -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

fclean:
	docker-compose -f srcs/docker-compose.yml down
	docker volume rm $$(docker volume ls -qf dangling=true)
	docker network rm $$(docker network ls -qf dangling=true)

re: down up

clean: down
	docker system prune -af --volumes

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

.PHONY: git_push