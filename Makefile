.PHONY: venv install test lint package

VENV_DIR?=.venv
PYTHON=$(VENV_DIR)/Scripts/python.exe

venv:
	python -m venv $(VENV_DIR)

install: venv
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt

test: install
	$(PYTHON) -m pytest -q

package:
	./scripts/package_lambda.sh