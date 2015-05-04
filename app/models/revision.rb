#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  scope :after_date, -> (date) { where('date > ?', date) }

  ####################
  # Instance methods #
  ####################
  def update(data={}, save=true)
    self.attributes = data
    self.save if save
  end
end
