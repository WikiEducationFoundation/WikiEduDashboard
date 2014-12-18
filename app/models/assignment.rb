class Assignment < ActiveRecord::Base
  belongs_to_many :users
  belongs_to :course
  has_one :article
end
