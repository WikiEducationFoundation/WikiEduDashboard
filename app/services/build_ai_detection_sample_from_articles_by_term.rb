# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/cumulative_diff"

# Builds a sample the way the March 2026 comparison did: for each term, a random
# set of articles that gained substantial text during a course, taking the
# cumulative diff from course start to course end as one unit. Terms before
# ChatGPT's release are labeled as a human-written baseline.
class BuildAiDetectionSampleFromArticlesByTerm < BuildAiDetectionSample
  def initialize(sample_name:, terms:, per_term: 100, min_characters: 3000, verbose: false)
    super(sample_name:, verbose:)
    terms.each { |slug| sample_term(slug, per_term, min_characters) }
  end

  private

  def sample_term(slug, per_term, min_characters)
    campaign = Campaign.find_by(slug:)
    return skip(slug, 'no such campaign') unless campaign

    ArticlesCourses.where(course: campaign.courses)
                   .where('character_sum > ?', min_characters)
                   .includes(:course, article: :wiki)
                   .order(Arel.sql('RAND()')).limit(per_term)
                   .each { |articles_course| add_articles_course(articles_course, campaign) }
  end

  def add_articles_course(articles_course, campaign)
    target = CumulativeDiff.new(articles_course).revision_target
    article = articles_course.article
    return skip(article.title, 'no revisions during the course') unless target

    add_revision_unit(wiki: article.wiki, **target,
                      article_id: article.id, course_id: articles_course.course_id,
                      campaign_slug: campaign.slug, namespace: article.namespace,
                      ground_truth: self.class.ground_truth_for_term(campaign.slug),
                      metadata: { 'character_sum' => articles_course.character_sum,
                                  'new_article' => articles_course.new_article,
                                  'references_count' => articles_course.references_count })
  end
end
