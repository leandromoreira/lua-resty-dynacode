# vi:ft=perl

use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: hello, world
This is just a simple demonstration of the
echo directive provided by ngx_http_echo_module.
--- config
location = /t {
    echo "hello, world!";
}
--- request
GET /t
--- response_body
hello, world!
--- error_code: 200
