class Domain < ApplicationRecord
  validates :name, uniqueness: true, presence: true
  has_many :plugins, dependent: :delete_all
end
