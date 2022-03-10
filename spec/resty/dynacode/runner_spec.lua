local runner = require "resty.dynacode.runner"
local events = require "resty.dynacode.event_emitter"

package.path = package.path .. ";spec/?.lua" -- necessary to load spec helper
local helper = require "resty.dynacode.spec_helper"

runner.setup({
  events=events,
})

local plugins
local original_plugins = {
  general={status="enabled",skip_domains={"skipable.com"}},
  domains={
    {
      name=".*domain.com",
      plugins={
        {name="p1",code="access1",phase="access"},
        {name="p2",code="access2",phase="access"},
        {name="p3",code="content1",phase="content"},
        {name="p4",code="access3",phase="access"},
        {name="p5",code="header_filter1",phase="header_filter", skip=true},
        {name="p10",code="body_filter2",phase="body_filter"},
      },
    },
    {
      name="*",
      plugins={
        {name="p0",code="body_filter1",phase="body_filter"},
      },
    },
  },
}

describe("runner #unit", function()
  describe("#run", function()
    before_each(function()
      plugins = helper.deepcopy(original_plugins)
      plugins = runner.phasify_plugins(plugins)
    end)

    it("runs the specified plugins", function()
      local myown_domain_variable = 3
      plugins.domains[1].content[1].compiled_code = function()
        myown_domain_variable = 42
      end

      runner.run(plugins, "myown.domain.com", "content")

      assert.are.same(myown_domain_variable, 42)
    end)

    it("signalizes runtime errors", function()
      local err = nil
      plugins.domains[1].content[1].compiled_code = function()
        -- luacheck: ignore
        redis.mysql.run.all = 3 -- should raise an error
      end
      runner.events.on(runner.events.RT_PLUGINS_STARTING, function()
        err = nil
      end)
      runner.events.on(runner.events.RT_PLUGINS_DONE, function()
        err = nil
      end)
      runner.events.on(runner.events.RT_PLUGINS_ERROR, function(plugin, plugin_err)
        assert.are.same(plugin.name, "p3")
        err = plugin_err
      end)

      runner.run(plugins, "myown.domain.com", "content")

      assert.are_not.same(err, nil)
    end)

    it("runs all the matching plugins", function()
      local myown_domain_variable = 1
      plugins.domains[1].access[1].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.domains[1].access[2].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.domains[1].access[3].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end

      runner.run(plugins, "myown.domain.com", "access")

      assert.are.same(myown_domain_variable, 4)
    end)

    it("always run the domain * plugins plus all the matching domains (plugins)", function()
      local myown_domain_variable = 1
      plugins.domains[1].body_filter[1].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.domains[2].body_filter[1].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end

      runner.run(plugins, "myown.domain.com", "body_filter")

      assert.are.same(myown_domain_variable, 3)
    end)

    it("skips all the matching plugins when disabled", function()
      local myown_domain_variable = 1
      plugins.domains[1].access[1].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.domains[1].access[2].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.domains[1].access[3].compiled_code = function()
        myown_domain_variable = myown_domain_variable + 1
      end
      plugins.general.status = "disabled"

      runner.run(plugins, "myown.domain.com", "access")

      assert.are.same(myown_domain_variable, 1)
    end)

    it("skips the skipable domain", function()
      local myown_domain_variable = 1
      runner.events.on(runner.events.RT_PLUGINS_STARTING, function()
        myown_domain_variable = 42
      end)
      runner.events.on(runner.events.RT_PLUGINS_DONE, function()
        myown_domain_variable = 42
      end)
      runner.events.on(runner.events.RT_PLUGINS_ERROR, function()
        myown_domain_variable = 42
      end)

      runner.run(plugins, "skipable.com", "access")

      assert.are.same(myown_domain_variable, 1)
    end)

    it("does not runs the unmatched domain", function()
      local myown_domain_variable = 3
      plugins.domains[1].content[1].compiled_code = function()
        myown_domain_variable = 42
      end

      runner.run(plugins, "myown.example.com", "content")

      assert.are.same(myown_domain_variable, 3)
    end)

    it("does not runs the unmatched phase", function()
      runner.run(plugins, "myown.example.com", "log")

      assert.are.same(plugins.domains[1].log, nil)
    end)

    it("does not runs skipable plugins", function()
      local myown_domain_variable = 3
      plugins.domains[1].header_filter[1].compiled_code = function()
        myown_domain_variable = 42
      end

      runner.run(plugins, "myown.domain.com", "header_filter")

      assert.are.same(myown_domain_variable, 3)
    end)
  end)

  describe("#phasify_plugins", function()
    it("groups plugins per phase on domain", function()
      plugins = helper.deepcopy(original_plugins)
      runner.phasify_plugins(plugins)

      assert.are.same(#plugins.domains[1].access, 3)
      assert.are.same(plugins.domains[1].access[1].name, "p1")
      assert.are.same(plugins.domains[1].access[3].name, "p4")
      assert.are.same(#plugins.domains[1].content, 1)
      assert.are.same(plugins.domains[1].log, nil)
    end)
  end)

end)
