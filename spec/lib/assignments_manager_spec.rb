require 'rails_helper'
require "#{Rails.root}/lib/assignments_manager"

describe AssignmentsManager do
  describe '.update_assignments' do
    it 'creates new assignments for existing articles' do
      course = create(:course, id: 1)
      user = create(:user, id: 1)
      create(:article, id: 1, namespace: 0, title: 'Existing_article')
      params = { 'users' => [{ 'id' => 1, 'wiki_id' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0 }] }
      allow(WikiEdits).to receive(:update_assignments)
      allow(WikiEdits).to receive(:update_course)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.last.article_title).to eq('Existing_article')
      expect(Assignment.last.article_id).to eq(1)
    end

    it 'creates new assignments for non-existent articles' do
      course = create(:course, id: 1)
      user = create(:user, id: 1)
      params = { 'users' => [{ 'id' => 1, 'wiki_id' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0 }] }
      allow(WikiEdits).to receive(:update_assignments)
      allow(WikiEdits).to receive(:update_course)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.last.article_title).to eq('Existing_article')
      expect(Assignment.last.article_id).to eq(nil)
    end
  end
end
