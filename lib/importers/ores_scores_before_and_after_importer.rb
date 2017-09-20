# frozen_string_literal: true

require "#{Rails.root}/lib/importers/revision_score_importer"

class OresScoresBeforeAndAfterImporter
  def initialize(campaign:)
    @campaign = campaign
    import_scores
  end

  private

  def import_scores
    first_revs = []
    last_revs = []
    @campaign.courses.each do |course|
      course.articles_courses.each do |ac|
        first_revs << ac.all_revisions.where(wiki_id: en_wiki_id).order('date ASC').first
        last_revs << ac.all_revisions.where(wiki_id: en_wiki_id).order('date ASC').last
      end
    end

    first_revs.select! { |rev| rev.present? && rev.wp10_previous.nil? }
    RevisionScoreImporter.new.update_previous_wp10_scores first_revs

    last_revs.select! { |rev| rev.present? && rev.wp10.nil? }
    RevisionScoreImporter.new.update_revision_scores last_revs
  end

  def en_wiki_id
    @en_wiki_id ||= Wiki.get_or_create(language: 'en', project: 'wikipedia').id
  end

end
