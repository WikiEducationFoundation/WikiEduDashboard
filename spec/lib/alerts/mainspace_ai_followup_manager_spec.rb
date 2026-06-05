require 'rails_helper'
require "#{Rails.root}/lib/alerts/mainspace_ai_followup_manager"

describe MainspaceAiFollowupManager do
  describe '#generate_followup_alerts_for_current_courses' do
    let(:course) { create(:course, start: 2.weeks.ago, end: 2.weeks.from_now) }
    let(:student) { create(:user, username: 'student') }
    let(:courses_user) do
      create(:courses_user, user_id: student.id,
                            course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:article) { create(:article, title: 'Test Article', namespace: 0) }

    before do
      courses_user
      course.campaigns << Campaign.default_campaign
      create(:ai_edit_alert, course_id: course.id, article_id: article.id,
                             user_id: student.id, created_at: 1.week.ago,
                             details: { article_title: article.title })
    end

    let(:small_addition) { 50 }
    let(:large_addition) { 5000 }

    let(:subject) { MainspaceAiFollowupManager.new([course]) }

    it 'creates a followup alert for major additions after the AI alert' do
      expect(MainspaceAiFollowupAlert.count).to eq(0)
      # Simulate significant additions after the AI alert
      ArticleCourseTimeslice.create!(course_id: course.id, article_id: article.id,
                                     start: 2.days.ago, character_sum: large_addition)


      subject.generate_followup_alerts
      expect(MainspaceAiFollowupAlert.count).to eq(1)

      followup_alert = MainspaceAiFollowupAlert.last
      expect(followup_alert.course_id).to eq(course.id)
      expect(followup_alert.article_id).to eq(article.id)
      expect(followup_alert.user_id).to eq(student.id)
      expect(followup_alert.details[:characters_added_after_alert]).to eq(5000)
    end

    it 'does not create a followup alert for only small additions' do
      expect(MainspaceAiFollowupAlert.count).to eq(0)
      # Simulate minor additions after the AI alert
      ArticleCourseTimeslice.create!(course_id: course.id, article_id: article.id,
                                     start: 2.days.ago, character_sum: small_addition)
      subject.generate_followup_alerts
      expect(MainspaceAiFollowupAlert.count).to eq(0)
    end
  end
end
