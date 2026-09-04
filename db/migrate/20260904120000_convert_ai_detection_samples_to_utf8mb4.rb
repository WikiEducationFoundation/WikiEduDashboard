# frozen_string_literal: true

# CreateAiDetectionSamples did not pin a charset, so the table took the
# database's default, which on production is 3-byte utf8: the first revision
# text containing a 4-byte character (a mathematical italic kappa) failed to
# insert. Wikipedia text can hold any Unicode, so the table must be utf8mb4
# like every other table in schema.rb.
# ROW_FORMAT=DYNAMIC first, as in ConvertTrainingModulesToUtf8Mb4: a utf8mb4
# varchar(255) index needs the 3072-byte prefix limit that COMPACT lacks.
class ConvertAiDetectionSamplesToUtf8mb4 < ActiveRecord::Migration[8.1]
  def up
    execute 'ALTER TABLE ai_detection_samples ROW_FORMAT=DYNAMIC'
    execute 'ALTER TABLE ai_detection_samples ' \
            'CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'
  end

  def down
    # Nothing to undo: a utf8mb4 table holds everything the utf8 table held.
  end
end
