.PHONY: lint template validate test

lint:
	helm lint .
	helm lint . -f values.yaml -f values-dev.yaml
	helm lint . -f values.yaml -f values-prod.yaml

template:
	helm template echo-web . -f values.yaml -f values-dev.yaml

validate:
	./validate.sh

test:
	helm test echo-web
