# frozen_string_literal: true

# == Schema Information
#
# Table name: wikis
#
#  id       :integer          not null, primary key
#  language :string(16)
#  project  :string(16)
#

# Class that represents meta.wikimedia.org
class MetaWiki < Wiki
  def base_url
    'https://meta.wikimedia.org/'
  end
end
