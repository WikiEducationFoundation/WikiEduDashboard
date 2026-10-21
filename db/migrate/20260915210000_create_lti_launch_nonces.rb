# frozen_string_literal: true

# Replay protection for inbound LTI 1.1 launches. OAuth 1.0a signs a nonce and
# a timestamp; a signature is otherwise reusable by anyone who observes it, so
# a launch is only accepted if its (key, nonce) pair has not been seen inside
# the timestamp window. The unique index is the enforcement, not a read: two
# simultaneous replays must not both pass a check-then-insert.
class CreateLtiLaunchNonces < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_launch_nonces do |t|
      t.integer :lti_consumer_key_id, null: false
      t.string :nonce, null: false
      t.datetime :created_at, null: false
      t.index %i[lti_consumer_key_id nonce], unique: true,
              name: 'index_lti_launch_nonces_on_key_and_nonce'
      t.index :created_at
    end
  end
end
