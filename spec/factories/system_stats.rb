# frozen_string_literal: true

FactoryBot.define do
  factory :system_stat do
    snapshot_date { Time.zone.today }
    total_edits { 100_000 }
    total_article_views { 500_000 }
    total_articles_improved { 5_000 }
    total_articles_created { 1_000 }
    active_programs_count { 50 }
    archived_programs_count { 200 }
    new_editors_count { 3_000 }
    new_editors_count_with_preregistration { 3_500 }
    active_facilitators_count { 25 }
    total_characters_added { 2_000_000 }
    wiki_stats do
      {
        'en.wikipedia.org' => {
          'edits' => 80_000, 'programs' => 200, 'articles_created' => 800, 'new_editors' => 2_500
        },
        'de.wikipedia.org' => {
          'edits' => 10_000, 'programs' => 30, 'articles_created' => 100, 'new_editors' => 300
        }
      }
    end
  end
end
