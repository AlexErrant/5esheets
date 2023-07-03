.DEFAULT_GOAL = help
.PHONY: api-doc api-explorer black check clean dev docker-build docker-run front-check help init mypy ruff run test trash-env

app-root = dnd5esheets
app-port = 8000
app-cli = poetry run python3 $(app-root)/cli.py
front-root = $(app-root)/front
npm = cd $(front-root) && npm
npm-run = $(npm) run


$(app-root)/schemas.py:

$(wildcard $(app-root)/api/*.py):

pyproject.toml:

poetry.lock: pyproject.toml
	@echo "\n[+] Locking dependencies"
	@poetry lock

requirements.txt: poetry.lock
	@echo "\n[+] Updating requirements.txt"
	@poetry export --without=dev -o requirements.txt

$(front-root)/package-lock.json: $(front-root)/package.json

$(front-root)/openapi.json: $(wildcard $(app-root)/api/*.py) $(app-root)/schemas.py
	@echo "\n[+] Generating the $(front-root)/openapi.json file"
	@# This one is a bit tricky, as the openapi.json file is generated by the fastapi app itself.
	@# To get it, we start the app in the background, give it 3s to start, request the endpoint,
	@# save the file locally and then kill the app with a SIGTERM.
	@cd $(app-root) && poetry run uvicorn $(app-root).app:app >/dev/null 2>&1 &
	@sleep 3  # Sorry dad
	@curl -s http://localhost:$(app-port)/openapi.json > $(front-root)/openapi.json
	@kill $$(lsof -i tcp:$(app-port) | grep -v PID | head -n 1 | awk '{ print $$2 }')
	@python3 scripts/preprocess_openapi_json.py

$(front-root)/src/5esheets-client: $(front-root)/openapi.json
	@echo "\n[+] Generating the typescript API client for the 5esheets API"
	@$(npm-run) generate-client

$(app-root)/data/items-base.json: $(app-root)/data/translations-items-fr.json
	@echo "\n[+] Fetching base equipment data"
	@curl -s https://raw.githubusercontent.com/5etools-mirror-1/5etools-mirror-1.github.io/master/data/items-base.json | poetry run python3 scripts/preprocess_base_item_json.py

$(app-root)/data/translations-items-fr.json:
	@echo "\n[+] Fetching items french translations"
	@curl -s https://gitlab.com/baktov.sugar/foundryvtt-dnd5e-lang-fr-fr/-/raw/master/dnd5e_fr-FR/compendium/dnd5e.items.json > $(app-root)/data/translations-items-fr.json

api-doc:  ## Open the 5esheets API documentation
	open http://localhost:$(app-port)/redoc

api-explorer:  ## Open the 5esheets API explorer (with interactive requests)
	open http://localhost:$(app-port)/docs

build: data front-build  ## Build the application

back-check: black mypy ruff

black:
	@echo "\n[+] Reformatting python files"
	@poetry run black $(app-root)/

check: back-check front-check ## Run all checks on the codebase

data: $(app-root)/data/items-base.json

deps-js: $(front-root)/package-lock.json
	@echo "\n[+] Installing js dependencies"
	@$(npm) install

deps-python: requirements.txt
	@echo "\n[+] Installing python dependencies"
	@poetry install

deps: deps-python deps-js  ## Install the development dependencies

docker-build: requirements.txt  ## Build the docker image
	@echo "\n[+] Building the docker image"
	@docker build -t brouberol/5esheets .

docker-run: docker-build  ## Run the docker image
	@echo "\n[+] Running the docker image"
	@docker run -it --rm -v $$(pwd)/$(app-root)/db:/usr/src/app/$(app-root)/db/ -p $(app-port):$(app-port) brouberol/5esheets

db-base-items: db-migrate ## Populate the base items in database
	@echo "\n[+] Populating the database with base items"
	@$(app-cli) db populate base-items

db-dev-fixtures: data db-base-items ## Populate the local database with development fixtures
	@echo "\n[+] Populating the database with development fixtures"
	@$(app-cli) db populate fixtures

db-migrate:  ## Run the SQL migrations
	@echo "\n[+] Applying the SQL migrations"
	@poetry run alembic upgrade head

init:  deps db-dev-fixtures run  ## Run the application for the first time

mypy:
	@echo "\n[+] Checking Python types"
	@poetry run mypy $(app-root)/

front-build: front-generate-api-client
	@echo "\n[+] Building the front app"
	@$(npm-run) build

front-check:  front-prettier ## Run all frontend checks

front-run-dev: front-build  ## Run the development frontend server
	@echo "\n[+] Running the dev frontend server"
	@$(npm-run) dev -- --open

front-generate-api-client: $(front-root)/src/5esheets-client ## Generate the API openapi.json file

front-prettier:
	@echo "\n[+] Running prettier on the codebase"
	@$(npm-run) prettier-check

ruff:
	@echo "\n[+] Running linter"
	@poetry run ruff --fix $(app-root)/

run: build  ## Run the app
	@echo  "\n[+] Running the FastApi server"
	@cd $(app-root) && poetry run uvicorn $(app-root).app:app --reload

test:  ## Run the project tests
	@echo "\n [+] Running the project tests"
	@DND5ESHEETS_ENV=test poetry run pytest

trash-env:  ## Delete all js dependencies and the python virtualenv
	@echo "\n [+] 🗑️🔥 Deleting the node_modules directory and the whole python virtualenv"
	@rm -rf $(front-root)/node_modules
	@rm -rf $$(poetry env info | grep Virtualenv -A 5| grep Path | awk '{ print $$2 }')

help:  ## Display help
	@grep -E '^[%a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}'
