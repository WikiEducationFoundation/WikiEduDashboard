# frozen_string_literal: true

# Regression test for issue #6813: Wikidata merge operations not counted in
# course stats. After a Wikidata item is merged into another, the source item
# becomes a redirect and drops out of the PetScan-driven category article list.
# RevisionDataManager#mark_scoped_articles correctly marks the resulting merge
# revision as scoped=false. The fix is in UpdateWikidataStatsTimeslice: it
# still analyzes non-scoped revisions and admits a merge_to contribution iff
# the merge target (parsed from the edit comment by the gem) is itself an
# in-scope article.

require 'rails_helper'
require "#{Rails.root}/lib/revision_data_manager"

describe 'issue #6813 Wikidata merge scoping' do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:course) do
    create(:article_scoped_program, start: '2026-04-01', end: '2026-04-30',
                                    home_wiki: wikidata)
  end
  let(:user) { create(:user, username: 'Epidosis') }

  # Q3350322 is a tracked Wikidata item still present in PetScan output.
  # Q112434841 was merged INTO Q3350322 on 2026-04-03 (rev 2477846959 has
  # comment "wbmergeitems-to:0||Q3350322"); its title is no longer in the
  # PetScan-refreshed list because PetScan excludes redirects.
  let(:tracked_target_title) { 'Q3350322' }
  let(:redirected_source_title) { 'Q112434841' }
  let(:merge_rev_id) { 2_477_846_959 }
  let(:normal_rev_id) { 2_479_212_246 }

  let(:tracked_target_revision) do
    [tracked_target_title, {
      'article' => { 'mw_page_id' => '3193529', 'title' => tracked_target_title,
                     'namespace' => '0', 'wiki_id' => wikidata.id },
      'revisions' => [
        { 'mw_rev_id' => normal_rev_id.to_s, 'date' => '20260407', 'characters' => '0',
          'mw_page_id' => '3193529', 'username' => 'Epidosis', 'new_article' => 'false',
          'system' => 'false', 'wiki_id' => wikidata.id }
      ]
    }]
  end
  let(:merge_source_revision) do
    [redirected_source_title, {
      'article' => { 'mw_page_id' => '107326531', 'title' => redirected_source_title,
                     'namespace' => '0', 'wiki_id' => wikidata.id },
      'revisions' => [
        { 'mw_rev_id' => merge_rev_id.to_s, 'date' => '20260403', 'characters' => '0',
          'mw_page_id' => '107326531', 'username' => 'Epidosis', 'new_article' => 'false',
          'system' => 'false', 'wiki_id' => wikidata.id }
      ]
    }]
  end

  let(:unrelated_merge_rev_id) { 9_999_999_999 }
  let(:unrelated_source_title) { 'Q987654321' }
  let(:unrelated_merge_revision) do
    [unrelated_source_title, {
      'article' => { 'mw_page_id' => '999999', 'title' => unrelated_source_title,
                     'namespace' => '0', 'wiki_id' => wikidata.id },
      'revisions' => [
        { 'mw_rev_id' => unrelated_merge_rev_id.to_s, 'date' => '20260415',
          'characters' => '0', 'mw_page_id' => '999999', 'username' => 'Epidosis',
          'new_article' => 'false', 'system' => 'false', 'wiki_id' => wikidata.id }
      ]
    }]
  end

  before do
    stub_wiki_validation
    create(:courses_user, course:, user:)
    # Simulate the post-PetScan-refresh state: the merge target is tracked,
    # the now-redirected merge source is not.
    allow(course).to receive(:scoped_article_titles)
      .and_return([tracked_target_title])
  end

  it 'admits merge_to from a non-scoped revision when the target is in scope' do
    manager = RevisionDataManager.new(wikidata, course)
    allow(manager).to receive(:get_revisions)
      .and_return([tracked_target_revision, merge_source_revision, unrelated_merge_revision])

    revisions = manager.fetch_revision_data_for_course('20260401', '20260430')

    target_rev    = revisions.find { |r| r.mw_rev_id == normal_rev_id }
    merge_rev     = revisions.find { |r| r.mw_rev_id == merge_rev_id }
    unrelated_rev = revisions.find { |r| r.mw_rev_id == unrelated_merge_rev_id }

    # mark_scoped_articles still drops the redirected source items.
    expect(target_rev.scoped).to eq(true)
    expect(merge_rev.scoped).to eq(false)
    expect(unrelated_rev.scoped).to eq(false)

    # All revisions reach the analyzer now (not just scoped ones), so merges
    # on now-redirected source pages get a chance to be classified.
    expect(WikidataDiffAnalyzer).to receive(:analyze)
      .with([normal_rev_id, merge_rev_id, unrelated_merge_rev_id])
      .and_return(
        diffs_analyzed_count: 3,
        diffs_not_analyzed: [],
        diffs: {
          normal_rev_id => { merge_to: 0, added_claims: 1 },
          merge_rev_id => { merge_to: 1, merge_target: tracked_target_title },
          unrelated_merge_rev_id => { merge_to: 1, merge_target: 'Q987654' }
        },
        total: {}
      )

    UpdateWikidataStatsTimeslice.new(course).update_revisions_with_stats(revisions)

    # Scoped rev keeps its full diff.
    expect(JSON.parse(target_rev.summary)).to include('added_claims' => 1)

    # Non-scoped merge into a scoped target → minimal merge_to summary admitted.
    expect(JSON.parse(merge_rev.summary)).to eq('merge_to' => 1)

    # Non-scoped merge into an unrelated target → still excluded.
    expect(unrelated_rev.summary).to be_nil

    # And the per-timeslice stats roll-up reflects the admitted merge.
    stats = UpdateWikidataStatsTimeslice.new(course).build_stats_from_revisions(revisions)
    expect(stats['merged to']).to eq(1)
    expect(stats['claims created']).to eq(1)
  end
end
