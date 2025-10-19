.PHONY: test lint package

test:
	python -m pytest -q

package:
	./scripts/package_lambda.sh