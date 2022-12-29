class Plugin < ApplicationRecord
  belongs_to :domain

  validates :name, uniqueness: true, presence: true
  validates :phase, :code, :domain, presence: true

  # extracted a valid list from https://github.com/openresty/lua-nginx-module#ngxget_phase
  PHASE_OPTIONS = ["rewrite", "balancer", "access", "content", "header_filter", "body_filter", "log"]

  def as_json(options={})
    super(options.merge(methods: :domain))
  end
end
