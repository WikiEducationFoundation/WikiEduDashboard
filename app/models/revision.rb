# == Schema Information
#
# Table name: revisions
#
#  id             :integer          not null, primary key
#  characters     :integer          default(0)
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  article_id     :integer
#  views          :integer          default(0)
#  date           :datetime
#  new_article    :boolean          default(FALSE)
#  deleted        :boolean          default(FALSE)
#  system         :boolean          default(FALSE)
#  wp10           :float(24)
#  wp10_previous  :float(24)
#  ithenticate_id :integer
#  report_url     :string(255)
#  wiki_id        :integer
#  native_id      :integer
#  page_id        :integer
#

#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  belongs_to :wiki
  scope :after_date, -> (date) { where('date > ?', date) }
  scope :live, -> { where(deleted: false) }
  scope :user, -> { where(system: false) }

  before_validation :set_defaults

  ####################
  # Instance methods #
  ####################
  def url
    # https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945
    return if article.nil?
    escaped_title = article.title.tr(' ', '_')
    language = Figaro.env.wiki_language
    "https://#{language}.wikipedia.org/w/index.php?title=#{escaped_title}&diff=prev&oldid=#{id}"
  end

  def update(data={}, save=true)
    self.attributes = data
    self.save if save
  end

  def infer_courses_from_user
    return [] if user.blank?
    user.courses.where('start <= ?', date).where('end >= ?', date)
  end

  def set_defaults
    self.wiki_id ||= Wiki.default_wiki.id
    self.native_id ||= self.id
    self.page_id ||= self.article_id
  end
end
