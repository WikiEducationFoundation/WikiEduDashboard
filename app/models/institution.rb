class Institution < ApplicationRecord
  has_many :courses, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
