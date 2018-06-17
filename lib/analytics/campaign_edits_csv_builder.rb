# frozen_string_literal: true

require 'csv'

class CampaignEditsCsvBuilder
  include ArticleHelper

  def initialize(campaign)
    @campaign = campaign
  end

  def generate_csv
    csv_data = [CSV_HEADERS]
    @campaign.courses.each do |course|
      @course = course
      course.all_revisions.includes(:wiki, :article, :user).each do |revision|
        csv_data << row(revision)
      end
    end
    CSV.generate { |csv| csv_data.each { |line| csv << line } }
  end

  private

  CSV_HEADERS = %w[
    revision_id
    campaign
    course
    timestamp
    wiki
    article_title
    diff
    username
    bytes_added
    new_article
    dashboard_edit
  ].freeze
  def row(revision)
    row = [revision.mw_rev_id]
    row << @campaign.title
    row << @course.title
    row << revision.date
    row << revision.wiki.base_url
    row << revision.article.full_title
    row << revision.url
    row << revision.user.username
    row << revision.characters
    row << revision.new_article
    row << revision.system
  end
end
