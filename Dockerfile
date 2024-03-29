FROM openresty/openresty:xenial

RUN apt-get update \
    && apt-get install -y \
        make cpanminus git \
    && cpanm -n Test::Nginx \
    && mkdir /src \
    && cd /src \
    && git config --global url."https://".insteadOf git:// \
    && luarocks install lua-resty-http 0.16.1-0 \
    && luarocks install lua-resty-mlcache 2.6.0-2 \
    && luarocks install luacheck \
    && luarocks install luacov \
    && luarocks install busted \
    && luarocks install ldoc

