class Institution < ApplicationRecord
  has_many :courses

  validates :name, presence: true, uniqueness: true

  def self.merge(survivor, duplicate)
    duplicate.courses.update_all(institution_id: survivor.id)
    duplicate.destroy
  end
end
