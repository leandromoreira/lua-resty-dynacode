lint:
	docker-compose run --rm lint

test: lint
	docker-compose run --rm test

doc:
	docker-compose run --rm doc
