PWD_PROJECT:=$(shell pwd)

run:
	docker run -it -v ${PWD_PROJECT}/rules.yaml:/api/rules.yaml \
		-v ${PWD_PROJECT}/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf \
		-v ${PWD_PROJECT}/src:/lua/src \
		-p 9090:9090 -p 8080:8080 -p 7070:7070 \
		openresty/openresty:xenial
