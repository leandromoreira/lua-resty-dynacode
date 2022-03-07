lint:
	docker-compose run --rm lint

test: lint
	docker-compose run --rm test

