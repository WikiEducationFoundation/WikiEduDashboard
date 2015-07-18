#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  scope :after_date, -> (date) { where('date > ?', date) }
  scope :live, -> { where(deleted: false) }
  scope :user, -> { where(system: false) }

  ####################
  # Instance methods #
  ####################
  def url
    # https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945

    if !article.nil?
      escaped_title = article.title.gsub(' ', '_')
      language = Figaro.env.wiki_language
      # rubocop:disable Metrics/LineLength
      "https://#{language}.wikipedia.org/w/index.php?title=#{escaped_title}&diff=prev&oldid=#{id}"
      # rubocop:enable Metrics/LineLength
    end
  end

  def update(data={}, save=true)
    self.attributes = data
    self.save if save
  end

  def happened_during_course?(course)
    date >= course.start && date <= course.end
  end
end
