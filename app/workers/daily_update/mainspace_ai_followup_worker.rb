require_dependency "#{Rails.root}/lib/alerts/mainspace_ai_followup_manager"

class MainspaceAiFollowupWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    MainspaceAiFollowupManager.new(Course.current).generate_followup_alerts
  end
end
