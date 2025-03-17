# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/assignment_updater"

describe AssignmentUpdater do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let!(:courses_user) do
    create(:courses_user, user_id: user.id, course_id: course.id, role: 0)
  end

  let!(:assignment) do
    create(:assignment, course_id: course.id,
                        user_id: user.id,
                        role: 0,
                        article_id: nil,
                        article_title: 'Deep_Sea_Fishing')
  end
  let!(:another_assignment) do
    create(:assignment, course_id: course.id,
                        user_id: user.id,
                        role: 0,
                        article_id: nil,
                        article_title: 'Scuba_Diving')
  end

  describe '.update_assignment_article_ids_and_titles' do
    it 'updates assignments with only titles to include a non-deleted article_id' do
      # Create deleted and non-deleted articles for same title
      create(:article, title: 'Deep_Sea_Fishing', deleted: true)
      non_deleted_article = create(:article, title: 'Deep_Sea_Fishing')
      expect(assignment.article_id).to eq(nil)
      described_class.update_assignment_article_ids_and_titles
      expect(Assignment.find(assignment.id).article_id).to eq(non_deleted_article.id)
      expect(another_assignment.article_id).to eq(nil)
    end

    it 'updates assignment titles to exactly match article titles' do
      create(:article, title: 'Deep_sea_FISHing')
      described_class.update_assignment_article_ids_and_titles
      expect(Assignment.find(assignment.id).article_title).to eq('Deep_sea_FISHing')
    end

    context 'when a case-variant assignment and an exact title assignment both exist' do
      let!(:case_variant_assignment) do
        create(:assignment, course_id: course.id,
                            user_id: user.id,
                            role: 0,
                            article_id: nil,
                            article_title: 'Deep_sea_FISHing')
      end
      let!(:article) { create(:article, title: 'Deep_sea_FISHing') }
      let!(:another_article) { create(:article, title: 'Scuba_DIVING') }

      it 'updates the records it can and does not raise an error' do
        described_class.update_assignment_article_ids_and_titles
        expect(Assignment.find(assignment.id).article_title).to eq('Deep_Sea_Fishing')
        expect(Assignment.find(another_assignment.id).article_title).to eq('Scuba_DIVING')
      end
    end
  end

  describe '.update_assignments_for_article' do
    context 'when two assignments for the same article id exist' do
      let!(:article) { create(:article, title: 'Deep_Sea_Fishing') }

      # Set both assignments to the same article id but different title
      let!(:assignment) do
        create(:assignment, course_id: course.id,
                            user_id: user.id,
                            role: 0,
                            article_id: article.id,
                            article_title: 'Deep_Sea_Fishing')
      end
      let!(:duplicate_assignment) do
        create(:assignment, course_id: course.id,
                            user_id: user.id,
                            role: 0,
                            article_id: article.id,
                            article_title: 'DSF')
      end

      it 'clean the article id and does not raise an error' do
        described_class.update_assignments_for_article(article)
        expect(Assignment.find(assignment.id).article_title).to eq('Deep_Sea_Fishing')
        expect(Assignment.find(assignment.id).article_id).to eq(article.id)
        expect(Assignment.find(duplicate_assignment.id).article_title).to eq('DSF')
        expect(Assignment.find(duplicate_assignment.id).article_id).to eq(nil)
      end
    end
  end

  describe '.clean_assignment_for_deleted_article' do
    it 'sets article_id to nil for article assignments' do
      deleted_article = create(:article, title: 'Deep_Sea_Fishing', deleted: true)
      assignment.update(article_id: deleted_article.id)
      expect(assignment.article_id).to eq(deleted_article.id)
      described_class.clean_assignment_for_deleted_article(deleted_article)
      expect(Assignment.find(assignment.id).article_id).to eq(nil)
    end
  end
end
