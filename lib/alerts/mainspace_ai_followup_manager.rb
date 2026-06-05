require_dependency "#{Rails.root}/lib/revision_scanner"

# Identifies articles that had mainspace AI alerts where
# the student made significant additions afterwards,
# and creates alerts for Wiki Experts to check that later work
class MainspaceAiFollowupManager
  def initialize(courses)
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @courses = courses
  end

  def generate_followup_alerts
    course_ids = @courses.map(&:id)
    mainspace_ai_alerts = AiEditAlert.where(course_id: course_ids).filter(&:mainspace?)
    mainspace_ai_alerts.each do |ai_alert|
      next if followup_alert_already_exists?(ai_alert)
      next unless significant_additions_after_ai_alert?(ai_alert)

      MainspaceAiFollowupAlert.create!(
        course_id: ai_alert.course_id,
        article_id: ai_alert.article_id,
        user_id: ai_alert.user_id,
        details: {
          ai_alert_id: ai_alert.id,
          characters_added_after_alert: ai_alert.characters_added_after_alert
        }
      )
    end
  end

  private

  def followup_alert_already_exists?(ai_alert)
    MainspaceAiFollowupAlert.exists?(course_id: ai_alert.course_id, article_id: ai_alert.article_id)
  end

  # Use the same threshold as RevisionScanner uses for determining which revisions to check for AI.
  CHARACTERS_ADDED_THRESHOLD = RevisionScanner::TEXT_DUMP_CHARACTERS
  def significant_additions_after_ai_alert?(ai_alert)
    ai_alert.characters_added_after_alert > CHARACTERS_ADDED_THRESHOLD
  end
end
