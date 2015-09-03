require 'rails_helper'
require "#{Rails.root}/lib/revision_analytics_service"

describe RevisionAnalyticsService do
  before do
    # build revisions and courses and stuff
    create(:course,
           id: 10001,
           start: 1.month.ago,
           end: Time.now + 1.month)
    create(:user,
           id: 1,
           wiki_id: 'Student_1')
    create(:courses_user,
           user_id: 1,
           course_id: 10001,
           role: 0)
    create(:article,
           id: 1,
           title: 'Student_1/A_great_draft',
           namespace: 2)
    create(:revision,
           id: 1,
           user_id: 1,
           article_id: 1,
           date: 1.day.ago,
           wp10: 60)
    create(:article,
           id: 2,
           title: 'Student_1/A_poor_draft',
           namespace: 2)
    create(:revision,
           id: 2,
           user_id: 1,
           article_id: 2,
           date: 1.day.ago,
           wp10: 20)
  end
  describe '.dyk_eligible' do
    it 'should return relevant revisions' do
      articles = RevisionAnalyticsService.dyk_eligible
      expect(articles).to include Article.find(1)
    end

    it 'should not return irrelevant revisions' do
      articles = RevisionAnalyticsService.dyk_eligible
      expect(articles).not_to include Article.find(2)
    end
  end
end
