class PluginsController < ApplicationController
  def index
    hash_response = {
      # simulating a general config, one could feature it within the domain model
      general: {
        status: "enabled",
        skip_domains: ["[\\\\w\\\\d\\\\.\\\\-]*server.local.com"],
      },
      domains: [],
    }
    Domain.all.map do |domain|
      hash_response[:domains] << {
        name: domain.name,
        plugins: domain.plugins.map {|p| {name: p.name, code: p.code, phase: p.phase}}
      }
    end

    render json: hash_response
  end
end
