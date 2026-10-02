# frozen_string_literal: true

# Server-side state for a verified LTI 1.1 launch, referenced by the short
# token we redirect with.
#
# The token began as a JWT carrying the whole normalized idtoken, which worked
# in every test and failed against real Canvas: the OAuth break-out stashes the
# token in the Rails session, and a token of that size overflowed the 4 KB
# session cookie (observed at 5879 bytes on staging). LTIAAS's own ltik is
# short for the same reason — it references state rather than carrying it.
class CreateLtiLegacyLaunches < ActiveRecord::Migration[8.1]
  def change
    create_table :lti_legacy_launches do |t|
      t.string :token, null: false
      t.text :idtoken, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.index :token, unique: true
      t.index :expires_at
    end
  end
end
