# vi:ft=perl

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);
use lib '.';

my $pwd = cwd();

workers(2);

#repeat_each(2);

plan tests => repeat_each() * (blocks() * 3) + 2;

no_long_string();


our $MainConfig = qq{
    user dialout dialout;
};

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_shared_dict  cache_dict 1m;

    init_by_lua_block {
        cache = require("resty.dynacode.cache")
        cache.setup({
          ttl=15,
          now=ngx.now,
          ngx_shared=ngx.shared.cache_dict
        })
    }
};


run_tests();

__DATA__

=== TEST 1: Caching
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
          local v = cache.get()

          if v then
            ngx.say(v  .. ":cached")
            return
          end

          cache.set("test")
          v = cache.get()
          ngx.say(v)
        }
    }
--- request
GET /t
--- response_body
test
--- no_error_log
[error]
