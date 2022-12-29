class ComputingUnit < ApplicationRecord
  validates :name, uniqueness: true, presence: true
  validates :phase, :code, presence: true

  PHASE_OPTIONS = ["rewrite", "balancer", "access", "content", "header_filter", "body_filter", "log"]
end
