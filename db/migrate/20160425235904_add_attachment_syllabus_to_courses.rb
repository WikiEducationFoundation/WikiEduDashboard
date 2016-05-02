class AddAttachmentSyllabusToCourses < ActiveRecord::Migration
  def self.up
    change_table :courses do |t|
      t.attachment :syllabus
    end
  end

  def self.down
    remove_attachment :courses, :syllabus
  end
end
