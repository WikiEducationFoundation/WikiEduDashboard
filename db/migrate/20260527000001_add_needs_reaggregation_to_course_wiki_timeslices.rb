# frozen_string_literal: true

class AddNeedsReaggregationToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :course_wiki_timeslices, :needs_reaggregation, :boolean, default: false
  end
end
