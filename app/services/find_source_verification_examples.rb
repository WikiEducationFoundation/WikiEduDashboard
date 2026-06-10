# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# Finds (claim, cited source) examples for source verification exercises,
# drawn from articles that the students of +course+ worked on. Only claims
# from content the students themselves added — and which is still present
# in the live article — are included. Examples come from the current live
# revision of each article, so the claims and citations are real, checkable
# Wikipedia content.
#
# This makes several MediaWiki API calls per article (revision history, a
# diff per student revision, plus the live article HTML), so it is intended
# for ad-hoc and exercise-preparation use rather than the update pipeline.
class FindSourceVerificationExamples
  # Bounds the number of per-revision diff fetches for a heavily-edited article.
  MAX_REVISIONS_PER_ARTICLE = 10

  attr_reader :examples

  def initialize(course, max_examples: 25, max_articles: 10)
    @course = course
    @max_examples = max_examples
    @max_articles = max_articles
    @examples = []
    find_examples
  end

  private

  def find_examples
    candidate_articles.each do |article|
      break if @examples.length >= @max_examples
      begin
        collect_examples_from(article)
      rescue StandardError => e
        Sentry.capture_exception e, extra: { article_id: article.id }
      end
    end
  end

  # The most-referenced mainspace articles students worked on are the
  # likeliest to yield usable examples.
  def candidate_articles
    @course.edited_articles_courses
           .where('articles_courses.references_count > 0')
           .where(articles: { namespace: Article::Namespaces::MAINSPACE })
           .order(references_count: :desc)
           .limit(@max_articles)
           .includes(:article)
           .map(&:article)
  end

  def collect_examples_from(article)
    rev_ids = student_revision_ids(article)
    return if rev_ids.empty?
    corpus = student_added_text(rev_ids, article.wiki)
    return if corpus.blank?
    extractor = ExtractClaimsAndSources.new(article.wiki, title: article.title,
                                                          only_within: corpus)
    append_examples(extractor, article)
  end

  def student_revision_ids(article)
    revisions = article_content(article.wiki).revision_history(
      article.mw_page_id, start_date: @course.end, end_date: @course.start
    )
    revisions.select { |rev| student_usernames.include?(rev['user']) }
             .filter_map { |rev| rev['revid'] }
             .first(MAX_REVISIONS_PER_ARTICLE)
  end

  # Each revision fetch makes several MediaWiki API calls in quick
  # succession; spacing them out avoids rate-limit (429) responses,
  # which the underlying parse/compare requests do not retry.
  REVISION_FETCH_DELAY = 1

  def student_added_text(rev_ids, wiki)
    rev_ids.each_with_index.filter_map do |rev_id, index|
      sleep REVISION_FETCH_DELAY unless index.zero?
      GetRevisionPlaintext.new(rev_id, wiki).plain_text
    end.join("\n\n")
  end

  def append_examples(extractor, article)
    remaining = @max_examples - @examples.length
    extractor.claims.first(remaining).each do |claim|
      @examples << claim.merge(article_title: extractor.article_title,
                               article_id: article.id,
                               mw_page_id: article.mw_page_id,
                               mw_rev_id: extractor.mw_rev_id,
                               wiki_domain: article.wiki.domain)
    end
  end

  def student_usernames
    @student_usernames ||= @course.students.pluck(:username)
  end

  def article_content(wiki)
    @article_contents ||= {}
    @article_contents[wiki.id] ||= WikiApi::ArticleContent.new(wiki)
  end
end
