# frozen_string_literal: true

class CreateSystemStats < ActiveRecord::Migration[7.0]
  def change
    create_table :system_stats do |t|
      t.date     :snapshot_date,              null: false
      t.bigint   :total_edits,               default: 0
      t.bigint   :total_article_views,        default: 0
      t.integer  :total_articles_improved,    default: 0
      t.integer  :total_articles_created,     default: 0
      t.integer  :active_programs_count,      default: 0
      t.integer  :archived_programs_count,    default: 0
      t.integer  :new_editors_count,          default: 0  # registered during course
      t.integer  :new_editors_count_with_preregistration, default: 0 # includes 60-day pre-window
      t.integer  :active_facilitators_count,  default: 0
      t.bigint   :total_characters_added,     default: 0
      t.text     :wiki_stats                  # Per-wiki breakdown, serialized as Hash
      t.timestamps
    end

    add_index :system_stats, :snapshot_date, unique: true
  end
end
