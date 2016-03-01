# == Schema Information
#
# Table name: wiki
#
#  id                :integer          not null, primary key
#  language          :string(16)
#  project           :string(16)
#
class CommonsWiki < Wiki
  def base_url
    "https://commons.wikimedia.org/"
  end
end
