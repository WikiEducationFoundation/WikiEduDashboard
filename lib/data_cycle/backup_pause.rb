# frozen_string_literal: true

module BackupPause
  def pause_until_no_backup
    sleep 60 until Backup.current_backup.nil?
  end
end
