class AddSentryTagUuidToCourseErrorRecords < ActiveRecord::Migration[6.0]
  def change
    add_column :course_error_records, :sentry_tag_uuid, :string, unique: true
  end
end
