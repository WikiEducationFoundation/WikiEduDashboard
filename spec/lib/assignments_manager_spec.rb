require 'rails_helper'
require "#{Rails.root}/lib/assignments_manager"

describe AssignmentsManager do
  describe '.update_assignments' do
    let(:course) { create(:course, id: 1) }
    let(:user) { create(:user, id: 1) }

    it 'creates new assignments for existing articles' do
      create(:article, id: 1, namespace: 0, title: 'Existing_article')
      params = { 'users' => [{ 'id' => 1, 'username' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0 }] }
      expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.last.article_title).to eq('Existing_article')
      expect(Assignment.last.article_id).to eq(1)
    end

    it 'creates new assignments for non-existent articles' do
      params = { 'users' => [{ 'id' => 1, 'username' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0 }] }
      expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.last.article_title).to eq('Existing_article')
      expect(Assignment.last.article_id).to eq(nil)
    end

    it 'deletes existing assignments' do
      create(:assignment,
             id: 1,
             user_id: 1,
             article_id: 1,
             article_title: 'Existing_article',
             course_id: 1,
             role: 0)
      params = { 'users' => [{ 'id' => 1, 'username' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0,
                                     'deleted' => 'true' }] }
      expect_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.all).to be_empty
    end

    it 'handles deletion of already-deleted assignments gracefully' do
      params = { 'users' => [{ 'id' => 1, 'username' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0,
                                     'deleted' => 'true' }] }
      expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.all).to be_empty
    end

    it 'handles duplicate assignments gracefully' do
      create(:assignment,
             user_id: 1,
             article_id: 1,
             article_title: 'Existing_article',
             course_id: 1,
             role: 0)
      create(:article, id: 1, namespace: 0, title: 'Existing_article')
      params = { 'users' => [{ 'id' => 1, 'username' => 'Ragesock' }],
                 'assignments' => [{ 'user_id' => 1,
                                     'article_title' => 'existing article',
                                     'role' => 0 }] }
      expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
      expect(Raven).to receive(:capture_exception)

      AssignmentsManager.update_assignments(course, params, user)
      expect(Assignment.all.count).to eq(1)
    end
  end
end
