# frozen_string_literal: true

# Per-install LTI 1.1 credentials the Dashboard issues itself, replacing
# LTIAAS's single global consumer key for the legacy path.
#
# A key is issued *for a course, by a user*: an instructor generates it from
# the unlisted page under their own course, pastes it into Canvas, and the
# first launch that uses it pins the key to that Canvas instance and binds the
# course. `secret` holds ActiveRecord-encrypted ciphertext, so it is text
# rather than a short string.
class CreateLtiConsumerKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_consumer_keys do |t|
      t.string :key, null: false
      t.text :secret, null: false
      t.integer :course_id, null: false
      t.integer :user_id, null: false
      # Set at the first launch: the Canvas root account's
      # tool_consumer_instance_guid. A pinned key is useless from any other
      # Canvas, which is the property LTIAAS's shared key cannot have.
      t.string :lms_instance_guid
      t.datetime :activated_at
      t.datetime :last_launch_at
      t.boolean :active, null: false, default: true
      t.timestamps
      t.index :key, unique: true
      t.index :course_id
    end
    # Deleting the course takes its keys with it, as it does the course's
    # binding. A key that survived would still verify a launch, whose course
    # claim then points at a row that no longer exists.
    add_foreign_key :lti_consumer_keys, :courses, on_delete: :cascade
  end
end
