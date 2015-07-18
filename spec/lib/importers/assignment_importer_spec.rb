require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/importers/assignment_importer"

describe ArticleImporter do
  describe '.update_article_ids' do
    it 'should update assignments with only titles to include an article_id' do
      create(:course, id: 1)
      create(:user, id: 1)
      create(:courses_user, user_id: 1, course_id: 1, role: 0)
      assignment = create(:assignment,
                          id: 1,
                          course_id: 1,
                          user_id: 1,
                          role: 0,
                          article_id: nil,
                          article_title: 'Deep_Sea_Fishing')
      assignment_no_article = create(:assignment,
                                     id: 2,
                                     course_id: 1,
                                     user_id: 1,
                                     role: 0,
                                     article_id: nil,
                                     article_title: 'Scuba_Diving')
      article = create(:article, title: 'Deep_Sea_Fishing')
      article_two = create(:article, title: 'Fly_Fishing')
      AssignmentImporter.update_article_ids([article, article_two])

      expect(Assignment.find(assignment.id).article_id).to eq(article.id)
      expect(assignment_no_article.article_id).to eq(nil)
    end
  end
end
