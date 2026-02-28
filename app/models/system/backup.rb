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

  def self.current_backup
    # Force uncaching because otherwise pause_until_no_backup may sleep more
    # than necessary since it doesn't detect the backup finished.
    ActiveRecord::Base.uncached do
      Backup.find_by(status: IN_PROCESS)
    end
  end
end
