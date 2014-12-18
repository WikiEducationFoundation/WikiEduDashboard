class User < ActiveRecord::Base
  has_and_belongs_to_many :courses
  # has_many :assignments
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions

  def contribution_url
    "https://en.wikipedia.org/wiki/Special:Contributions/#{self.wiki_id}"
  end
end

# Roles:
#   Instructors
#   Advisors
#   Student