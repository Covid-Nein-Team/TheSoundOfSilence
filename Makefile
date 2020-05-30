# thesoundofsilence Makefile
# Created by: Covid Nein Team
PORT ?= 8080

.PHONY: help run debug env-production env-development env-npm dev-create-test test

help:
	@echo
	@echo "thesoundofsilence usage:"
	@echo "  make <target>"
	@echo
	@echo "targets:"
	@echo "  help              print this help"
	@echo "  run               run the app (127.0.0.1:$(PORT))"
	@echo "  debug             run the app in showcase mode"
	@echo "  test              run the tests"
	@echo "  test-interactive  run the tests interactively"
	@echo "  env-production    setup the conda environment"
	@echo "  env-development   setup the conda dev environment"
	@echo "  env-npm           setup js build env"
	@echo "  dev-create-test   create a new shinytest test"
	@echo

run:
	R -e "shiny::shinyOptions(shiny.autoreload = TRUE); shiny::runApp('./', port=$(PORT))"

debug:
	R -e "shiny::runApp('./', port=$(PORT), display.mode='showcase')"

test:
	R -f run_tests.R

test-interactive: export R_BROWSER = 'xdg-open'
test-interactive:
	for testfile in `ls ./tests/test*.R`; do  \
      echo "\n\nRUNNING SHINYTEST: $${testfile}"; \
      echo "shinytest::testApp('.', \"$$(basename -- $$testfile '.R')\"); q()" > .Rprofile; \
      R --no-save; \
      rm -f .Rprofile; \
	done

deploy:
	R -f deploy_app.R

env-production:
	conda env create --force -f=environment.yml -n spaceapps2020

env-development: env-production
	conda env update -f=environment-dev.yml -n spaceapps2020

env-npm:
	npm install
	npm run build

build:
	npm run build

dev-create-test: export R_BROWSER = 'xdg-open'
dev-create-test:
	R -e "shinytest::recordTest('.', loadTimeout=10000)"
