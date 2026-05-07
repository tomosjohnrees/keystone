.DEFAULT_GOAL := help

DC  := docker compose
WEB := web

# Run a command in the web container.
# Uses `exec` when web is already up (fast); falls back to a one-shot `run --rm`.
# Usage: $(call IN_WEB,bin/rails console)
define IN_WEB
if $(DC) ps --status running --services 2>/dev/null | grep -qx $(WEB); then $(DC) exec $(WEB) $(1); else $(DC) run --rm $(WEB) $(1); fi
endef

##@ General

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

##@ Docker lifecycle

.PHONY: setup
setup: ## Build the dev image, install gems, and prepare the database
	$(DC) build
	$(DC) run --rm $(WEB) bundle install
	$(DC) run --rm $(WEB) bin/rails db:prepare

.PHONY: build
build: ## Rebuild the dev image
	$(DC) build

.PHONY: up
up: ## Start the app in the foreground (Ctrl-C to stop)
	$(DC) up

.PHONY: up-d
up-d: ## Start the app in the background
	$(DC) up -d

.PHONY: down
down: ## Stop and remove containers
	$(DC) down

.PHONY: restart
restart: ## Restart containers
	$(DC) restart

.PHONY: logs
logs: ## Tail container logs
	$(DC) logs -f

.PHONY: ps
ps: ## List running containers
	$(DC) ps

.PHONY: shell
shell: ## Open a bash shell in the web container
	@$(call IN_WEB,bash)

.PHONY: jobs
jobs: ## Start the solid_queue worker (background)
	$(DC) --profile jobs up -d jobs

##@ Rails

.PHONY: console
console: ## Open a Rails console
	@$(call IN_WEB,bin/rails console)

.PHONY: routes
routes: ## List all application routes
	@$(call IN_WEB,bin/rails routes)

##@ Database

.PHONY: db-create
db-create: ## Create the development and test databases
	@$(call IN_WEB,bin/rails db:create)

.PHONY: db-migrate
db-migrate: ## Run pending migrations
	@$(call IN_WEB,bin/rails db:migrate)

.PHONY: db-rollback
db-rollback: ## Roll back the most recent migration
	@$(call IN_WEB,bin/rails db:rollback)

.PHONY: db-seed
db-seed: ## Load db/seeds.rb
	@$(call IN_WEB,bin/rails db:seed)

.PHONY: db-reset
db-reset: ## Drop, recreate, migrate, and seed the database
	@$(call IN_WEB,bin/rails db:reset)

##@ Quality

.PHONY: test
test: ## Run the test suite
	@$(call IN_WEB,bundle exec rspec)

.PHONY: lint
lint: ## Lint Ruby code with RuboCop
	@$(call IN_WEB,bin/rubocop)

.PHONY: lint-fix
lint-fix: ## Lint and autocorrect safe offenses
	@$(call IN_WEB,bin/rubocop -A)

.PHONY: security
security: ## Run Brakeman and bundler-audit scans
	@$(call IN_WEB,bin/brakeman --no-pager)
	@$(call IN_WEB,bin/bundler-audit)

.PHONY: ci
ci: lint security test ## Run all CI-equivalent checks (lint + security + test)

##@ Maintenance

.PHONY: bundle
bundle: ## Re-run bundle install in the container
	@$(call IN_WEB,bundle install)

.PHONY: clean
clean: ## Stop containers and remove volumes (DESTRUCTIVE — wipes the dev DB)
	$(DC) down -v
