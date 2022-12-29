.PHONY: run test

run:
	docker-compose run --rm --service-ports web
test:
	docker-compose run --rm web bundle exec rspec
