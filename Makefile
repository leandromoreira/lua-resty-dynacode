run: yaml_2_json
	docker-compose run --rm --service-ports app

lint:
	docker-compose run --rm lint

test:
	docker-compose run --rm test

yaml_2_json:
	docker run --rm -v "${PWD}":/workdir mikefarah/yq -o=json eval rules.yaml > response.json

webp:
	http -v http://localhost:8080/path/to/video.webp Host:webp.local.com

gateway:
	http -v http://localhost:7070/path/to/video.webp Host:gateway.local.com

api:
	http -v http://localhost:6060/api/entities Host:apiserver.local.com

metrics:
	http -v http://localhost:5050/metrics Host:metrics.server.local.com
