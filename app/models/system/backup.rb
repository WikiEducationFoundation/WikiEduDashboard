# frozen_string_literal: true

# == Schema Information
#
# Table name: backups
#
#  id           :bigint           not null, primary key
#  scheduled_at :datetime
#  start        :datetime
#  end          :datetime
#  status       :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Backup < ApplicationRecord
  IN_PROCESS = %w[waiting running].freeze
  # A healthy backup run touches its row within minutes. Anything older is an
  # orphaned row left behind by a crashed backup.sh (e.g., host restart), and
  # must not indefinitely block CourseDataUpdateWorker via
  # LogSidekiqStatus#pause_until_no_backup.
  FRESH_WINDOW = 2.hours

  def self.current_backup
    # Force uncaching because otherwise pause_until_no_backup may sleep more
    # than necessary since it doesn't detect the backup finished.
    ActiveRecord::Base.uncached do
      Backup.where(status: IN_PROCESS)
            .where('updated_at >= ?', FRESH_WINDOW.ago)
            .order(id: :desc)
            .first
    end
  end
end
