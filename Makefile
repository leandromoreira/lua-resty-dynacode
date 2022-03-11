lint:
	docker-compose run --rm lint

test: lint
	docker-compose run --rm test

prove_test:
	docker-compose run --rm prove_test

doc:
	docker-compose run --rm doc
