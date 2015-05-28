#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  scope :after_date, -> (date) { where('date > ?', date) }

  ####################
  # Instance methods #
  ####################
  def url
    # https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945

    escaped_title = article.title.gsub(' ', '_')
    language = Figaro.env.wiki_language
    # rubocop:disable Metrics/LineLength
    "https://#{language}.wikipedia.org/w/index.php?title=#{escaped_title}&diff=prev&oldid=#{id}"
    # rubocop:enable Metrics/LineLength
  end

  def update(data={}, save=true)
    self.attributes = data
    self.save if save
  end
end
