.DEFAULT_GOAL = help
.PHONY: api-doc api-explorer black check clean docker-build docker-run front-check help init mypy ruff run test trash-env

UNAME_S := $(shell uname -s)
PWD = $(shell pwd)
ifeq ($(UNAME_S),Linux)
	libsqlite = lib/libsqlite3.so
	ld_preload = LD_PRELOAD=$(PWD)/$(libsqlite)
else ifeq ($(UNAME_S),Darwin)
	libsqlite = lib/libsqlite3.0.dylib
	ld_preload = DYLD_LIBRARY_PATH=$(PWD)/lib
endif

app-root = dnd5esheets
app-port = 8000
front-root = $(app-root)/front
api-client-root = $(front-root)/src/5esheets-client
npm = cd $(front-root) && npm
npm-run = $(npm) run
poetry-run = $(ld_preload) poetry run
python = $(poetry-run) python3
app-cli = $(poetry-run) dnd5esheets-cli
FRONT_FILES = $(shell find $(front-root)/src -type f -name '*.[jt]s*')

sed_i = sed -i
ifeq ($(UNAME_S),Darwin)
	sed_i += ''
endif

include $(app-root)/*/*.mk


$(app-root)/schemas.py:

$(wildcard $(app-root)/api/*.py):

$(app-root)/models.py:

scripts/cleanup_makefile2dot_output.py:

pyproject.toml:

poetry.lock: pyproject.toml
	@echo "\n[+] Locking dependencies"
	@poetry lock

doc/model_graph.png: $(app-root)/models.py
	@echo "\n[+] Generating SQL model graph"
	@./scripts/generate_model_graph.py $@

doc/makefile.png: Makefile scripts/cleanup_makefile2dot_output.py
	@echo "\n[+] Generating a visual graph representation of the Makefile"
	@$(poetry-run) makefile2dot | ./scripts/cleanup_makefile2dot_output.py | dot -Tpng > $@

lib/libsqlite3.so:
	@echo "\n[+] Building libsqlite3 for linux"
	@./scripts/compile-libsqlite-linux.sh

lib/libsqlite3.0.dylib:
	@echo "\n[+] Building libsqlite3 for macos"
	@./scripts/compile-libsqlite-macos.sh

$(front-root)/package-lock.json: $(front-root)/package.json

$(front-root)/openapi.json: $(wildcard $(app-root)/api/*.py) $(app-root)/schemas.py
	@echo "\n[+] Generating the $(front-root)/openapi.json file"
	@# This one is a bit tricky, as the openapi.json file is generated by the fastapi app itself.
	@# To get it, we start the app in the background, give it 3s to start, request the endpoint,
	@# save the file locally and then kill the app with a SIGTERM.
	@cd $(app-root) && $(poetry-run) uvicorn --factory $(app-root).app:create_app >/dev/null 2>&1 &
	@sleep 3  # Sorry dad
	@curl -s http://localhost:$(app-port)/openapi.json > $@
	@kill $$(lsof -i tcp:$(app-port) | grep -v PID | head -n 1 | awk '{ print $$2 }')
	@./scripts/preprocess_openapi_json.py

$(front-root)/dist/index.html: $(FRONT_FILES)
	@echo "\n[+] Building the front app"
	@$(npm-run) build

$(api-client-root): $(front-root)/openapi.json
	@echo "\n[+] Generating the typescript API client for the 5esheets API"
	@$(npm-run) generate-client

.git/hooks/pre-push:
	@cp scripts/pre-push $@

api-doc:  ## Open the 5esheets API documentation
	open http://localhost:$(app-port)/redoc

api-explorer:  ## Open the 5esheets API explorer (with interactive requests)
	open http://localhost:$(app-port)/docs

build: $(libsqlite) doc/model_graph.png doc/makefile.png data front-build  ## Build the application

back-check: black mypy ruff

back-test:  ## Run the backend tests
	@echo "\n[+] Running the backend tests"
	@DND5ESHEETS_ENV=test $(poetry-run) pytest

black:
	@echo "\n[+] Reformatting python files"
	@$(poetry-run) black --check $(app-root)/

check: back-check front-check ## Run all checks on the codebase

data: $(app-root)/data/items-base.json $(app-root)/data/spells.json

deps-js: $(front-root)/package-lock.json
	@echo "\n[+] Installing js dependencies"
	@$(npm) install

deps-python: poetry.lock
	@echo "\n[+] Installing python dependencies"
	@poetry install

deps: deps-python deps-js  ## Install the development dependencies

docker-build:  ## Build the docker image
	@echo "\n[+] Building the docker image"
	@docker build -t brouberol/5esheets .

docker-run: docker-build  ## Run the docker image
	@echo "\n[+] Running the docker image"
	@docker run -it --rm --name 5esheets -v $$(pwd)/$(app-root)/db:/usr/src/app/$(app-root)/db/ -p $(app-port):$(app-port) brouberol/5esheets

db-base-items: ## Populate the base items in database
	@echo "\n[+] Populating the database with base items"
	@$(app-cli) db populate base-items

db-spells: ## Populate the spells in database
	@echo "\n[+] Populating the database with spells"
	@$(app-cli) db populate spells

db-dev-fixtures: data db-migrate db-base-items db-spells ## Populate the local database with development fixtures
	@echo "\n[+] Populating the database with development fixtures"
	@$(app-cli) db populate fixtures

db-migrate:  ## Run the SQL migrations
	@echo "\n[+] Applying the SQL migrations"
	@$(poetry-run) alembic upgrade head

hooks: .git/hooks/pre-push

init:  hooks deps db-dev-fixtures run  ## Run the application for the first time

mypy:
	@echo "\n[+] Checking Python types"
	@$(poetry-run) mypy $(app-root)/

front-build: $(front-root)/dist/index.html

front-check:  front-lint front-prettier front-typecheck ## Run all frontend checks

front-test: ## Run the frontend unit tests
	@echo "\n[+] Running the frontend tests"
	@$(npm-run) test

front-run-dev: front-build  ## Run the development frontend server
	@echo "\n[+] Running the dev frontend server"
	@$(npm-run) dev -- --open

front-generate-api-client: $(api-client-root) ## Generate the API openapi.json file

front-lint:
	@echo "\n[+] Linting the front codebase"
	@$(npm-run) lint

front-typecheck:
	@echo "\n[+] Type checking the front codebase"
	@$(npm-run) typecheck

front-prettier:
	@echo "\n[+] Running prettier on the front codebase"
	@$(npm-run) prettier-check

ruff:
	@echo "\n[+] Running linter"
	@$(poetry-run) ruff $(app-root)/

run: admin-statics build  ## Run the app
	@echo  "\n[+] Running the FastApi server"
	@cd $(app-root) && $(poetry-run) uvicorn --factory $(app-root).app:create_app --reload

test:  back-test front-test ## Run the project tests

trash-env:  ## Delete all js dependencies and the python virtualenv
	@echo "\n[+] 🗑️🔥 Deleting the node_modules directory and the whole python virtualenv"
	@rm -rf $(front-root)/node_modules
	@rm -rf $$(poetry env info | grep Virtualenv -A 5| grep Path | awk '{ print $$2 }')

help:  ## Display help
	@grep -E '^[%a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | ./scripts/format_makefile.py
