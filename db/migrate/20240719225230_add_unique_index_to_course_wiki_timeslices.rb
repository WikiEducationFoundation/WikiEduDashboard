class AddUniqueIndexToCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :course_wiki_timeslices, [:course_id, :wiki_id, :start, :end], unique: true, name: 'course_wiki_timeslice_by_course_wiki_start_and_end'
  end
end
