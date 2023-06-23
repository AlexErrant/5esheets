.DEFAULT_GOAL = help
.PHONY: api-doc apixplorer black check dev dnd5esheets/templates/spellbook.html \
	docker-build docker-run init mypy ruff run svelte-check help

ifeq (, $(shell which poetry))
$(error "No poetry executable found in $$PATH. Follow these instructions to install it: \
https://python-poetry.org/docs/#installing-with-the-official-installer")
endif

app-root = dnd5esheets
app-port = 8000
app-cli = poetry run python3 $(app-root)/cli.py
npm = cd $(app-root)/client && npm
npm-run = $(npm) run

$(app-root)/translations/messages.pot: $(app-root)/templates/*.html
	poetry run pybabel extract --omit-header -F babel.cfg -o $(app-root)/translations/messages.pot .

$(wildcard $(app-root)/translations/*/*/messages.po): $(app-root)/translations/messages.pot
	poetry run pybabel update --omit-header --no-fuzzy-matching -i $(app-root)/translations/messages.pot -d $(app-root)/translations

$(wildcard $(app-root)/translations/*/*/messages.mo): $(wildcard $(app-root)/translations/*/*/messages.po)
	poetry run pybabel compile --use-fuzzy -d $(app-root)/translations

$(app-root)/templates/spellbook.html:
	python3 scripts/generate_spellbook.py > $(app-root)/templates/spellbook.html

$(app-root)/client/openapi.json: $(wildcard $(app-root)/api/*.py) $(app-root)/schemas.py
	@echo  "\n[+] Generating the $(app-root)/client/openapi.json file"
	@# This one is a bit tricky, as the openapi.json file is generated by the fastapi app itself.
	@# To get it, we start the app in the background, give it 3s to start, request the endpoint,
	@# save the file locally and then kill the app with a SIGTERM.
	@cd $(app-root) && poetry run uvicorn $(app-root).app:app >/dev/null 2>&1 &
	@sleep 3  # Sorry dad
	@curl -s http://localhost:$(app-port)/openapi.json > $(app-root)/client/openapi.json
	@kill $$(lsof -i tcp:$(app-port) | grep -v PID | head -n 1 | awk '{ print $$2 }')
	@python3 scripts/preprocess_openapi_json.py

$(app-root)/schemas.py:

$(wildcard $(app-root)/api/*.py):

$(app-root)/client/src/5esheet-client: $(app-root)/client/openapi.json
	@echo  "\n[+] Generating the typescript API client for the 5esheets API"
	@$(npm-run) generate-client

api-doc:  ## Open the 5esheets API documentation
	open http://localhost:$(app-port)/redoc

api-explorer:  ## Open the 5esheets API explorer (with interactive requests)
	open http://localhost:$(app-port)/docs

build: svelte-build  ## Build the application

black:
	@echo "\n[+] Reformatting python files"
	@poetry run black $(app-root)/

check: black mypy ruff svelte-check ## Run all checks on the python codebase

dev:  ## Install the development environment
	@echo "\n[+] Installing dependencies"
	@poetry install
	$(npm) install

docker-build:  build requirements.txt  ## Build the docker image
	@echo "\n[+] Building the docker image"
	@docker build -t brouberol/5esheets .

docker-run:  docker-build  ## Run the docker image
	@echo "\n[+] Running the docker image"
	@docker run -it --rm -v $$(pwd)/$(app-root)/db:/usr/src/app/$(app-root)/db/ -p $(app-port):$(app-port) brouberol/5esheets

db-migrate:  ## Run the SQL migrations
	@echo "\n[+] Applying SQL migrations"
	@poetry run alembic upgrade head

db-dev-fixtures:  db-migrate ## Populate the local database with development fixtures
	@echo "\n[+] Populating the database with development fixtures"
	@$(app-cli) db populate

init:  dev db-dev-fixtures run  ## Run the application for the first time

mypy:
	@echo "\n[+] Checking types"
	@poetry run mypy $(app-root)/

poetry.lock: pyproject.toml
	@echo "\n[+] Locking dependencies"
	@poetry lock

pyproject.toml:

requirements.txt: poetry.lock
	@echo "\n[+] Updating requirements.txt"
	@poetry export --without=dev -o requirements.txt

svelte-build: svelte-generate-api-client
	@echo "\n[+] Building svelte app"
	@$(npm-run) build

svelte-check:
	$(npm-run) check

svelte-generate-api-client: $(app-root)/client/src/5esheet-client ## Generate the API openapi.json file

ruff:
	@echo "\n[+] Running linter"
	@poetry run ruff --fix $(app-root)/

run: build  ## Run the app
	@echo  "\n[+] Running FastApi server"
	@cd $(app-root) && poetry run uvicorn $(app-root).app:app --reload

translationsxtract: $(app-root)/translations/messages.pot  ## Extract all strings to translate from jinja templates

translations-update: $(wildcard $(app-root)/translations/*/*/messages.po)  ## Update the language catalogs with new translations

translations-compile: $(wildcard $(app-root)/translations/*/*/messages.mo)  ## Compile translations into a .mo file

help:  ## Display help
	@grep  '^[%a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-26s\033[0m %s\n", $$1, $$2}'
