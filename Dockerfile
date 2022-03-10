FROM openresty/openresty:xenial

RUN apt-get update \
    && apt-get install -y \
       git \
    && mkdir /src \
    && cd /src \
    && git config --global url."https://".insteadOf git:// \
    && luarocks install lua-resty-http 0.16.1-0 \
    && luarocks install lua-resty-mlcache 2.5.0-1 \
    && luarocks install luacheck \
    && luarocks install luacov \
    && luarocks install busted \
    && luarocks install ldoc

