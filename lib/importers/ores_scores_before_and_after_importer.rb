# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/revision_score_importer"

class OresScoresBeforeAndAfterImporter
  def self.import_all
    ArticlesCourses.find_in_batches(batch_size: 2000) do |ac_batch|
      new(articles_courses: ac_batch)
    end
  end

  def initialize(articles_courses:)
    @articles_courses = articles_courses
    RevisionScoreImporter::AVAILABLE_WIKIPEDIAS.each do |language|
      wiki = Wiki.get_or_create(language: language, project: 'wikipedia')
      import_scores(wiki)
    end
  end

  private

  def import_scores(wiki)
    first_revs = []
    last_revs = []
    @articles_courses.each do |ac|
      first_revs << ac.all_revisions.where(wiki: wiki).order('date ASC').first
      last_revs << ac.all_revisions.where(wiki: wiki).order('date ASC').last
    end

    first_revs.select! { |rev| rev.present? && rev.wp10_previous.nil? }
    RevisionScoreImporter.new(wiki.language).update_previous_wp10_scores first_revs

    last_revs.select! { |rev| rev.present? && rev.wp10.nil? }
    RevisionScoreImporter.new(wiki.language).update_revision_scores last_revs
  end
end
