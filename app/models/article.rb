class Article < ActiveRecord::Base
  has_many :revisions
end
