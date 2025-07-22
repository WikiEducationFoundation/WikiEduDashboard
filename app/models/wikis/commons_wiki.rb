# frozen_string_literal: true

# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#

# Class that represents Wikimedia Commons
class CommonsWiki < Wiki
  def base_url
    'https://commons.wikimedia.org/'
  end
end
