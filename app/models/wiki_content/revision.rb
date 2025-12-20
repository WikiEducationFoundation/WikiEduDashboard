# frozen_string_literal: true
# == Schema Information
#
# Table name: revisions
#
#  id                :integer          not null, primary key
#  characters        :integer          default(0)
#  created_at        :datetime
#  updated_at        :datetime
#  user_id           :integer
#  article_id        :integer
#  views             :bigint           default(0)
#  date              :datetime
#  new_article       :boolean          default(FALSE)
#  deleted           :boolean          default(FALSE)
#  wp10              :float(24)
#  wp10_previous     :float(24)
#  system            :boolean          default(FALSE)
#  ithenticate_id    :integer
#  wiki_id           :integer
#  mw_rev_id         :integer
#  mw_page_id        :integer
#  features          :text(65535)
#  features_previous :text(65535)
#  summary           :text(65535)
#
#= Revision model
class Revision < ApplicationRecord
  belongs_to :user
  belongs_to :article
  belongs_to :wiki

  # Helps with importing data
  alias_attribute :rev_id, :mw_rev_id

  validates :mw_page_id, presence: true
  validates :mw_rev_id, presence: true

  serialize :features, type: Hash
  serialize :features_previous, type: Hash
end
