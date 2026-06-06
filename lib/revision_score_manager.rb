# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/lift_wing_api"

# Scores article revisions with wp10 via LiftWing. The revision list itself is
# fetched client-side (directly from the MediaWiki API); this class only turns
# a list of revision ids into wp10 scores, cached per revision.
class RevisionScoreManager
  def initialize(article)
    @article = article
    @wiki = article.wiki
  end

  # Returns { "rev_id" => wp10_or_nil } for the given revision ids. Returns an
  # empty hash for wikis with no LiftWing articlequality model.
  def scores_for(rev_ids)
    return {} unless LiftWingApi.valid_wiki?(@wiki)
    ids = Array(rev_ids).map(&:to_i).uniq
    ids.index_with { |rev_id| cached_score(rev_id) }
       .transform_keys(&:to_s)
  end

  private

  def cached_score(rev_id)
    Rails.cache.fetch("wp10/#{@wiki.id}/#{rev_id}", expires_in: 1.day) do
      lift_wing.get_revision_data([rev_id]).dig(rev_id.to_s, 'wp10')
    end
  end

  def lift_wing
    @lift_wing ||= LiftWingApi.new(@wiki)
  end
end
