class CommonsUpload < ActiveRecord::Base
  belongs_to :user

  ####################
  # Instance methods #
  ####################
  def url
    "https://commons.wikimedia.org/wiki/#{file_name}"
  end
end
