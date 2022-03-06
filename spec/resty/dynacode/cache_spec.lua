local cache = require "resty.dynacode.cache"

cache.setup({
    now = ngx.now,
    ttl = 2,
    ngx_shared = ngx.shared.test_shm, -- this shared memory is applied at resty_busted
})

describe("cache", function()
  before_each(function()
    ngx.shared.test_shm:flush_all()
  end)

  it("sets a value", function()
    cache.set("a value")
    local result = cache.get()

    assert.are.same("a value", "a value")
  end)

  it("signalizes when cache is fresh", function()
    cache.set("a value")
    local should_refresh = cache.should_refresh()

    assert.is_false(should_refresh)
  end)

  it("signalizes when cache is stale", function()
    cache.set("a value")
    ngx.sleep(cache.ttl + 1)

    local should_refresh = cache.should_refresh()

    assert.is_true(should_refresh)
  end)
end)
