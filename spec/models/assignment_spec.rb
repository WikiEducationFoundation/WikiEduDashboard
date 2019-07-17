# frozen_string_literal: true

# == Schema Information
#
# Table name: assignments
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  user_id       :integer
#  course_id     :integer
#  article_id    :integer
#  article_title :string(255)
#  role          :integer
#  wiki_id       :integer
#  sandbox_url   :text(65535)
#

require 'rails_helper'

describe Assignment do
  before { stub_wiki_validation }

  describe 'assignment creation' do
    context 'when no similar assignments exist' do
      it 'creates Assignment objects' do
        course = create(:course)
        assignment = create(:assignment, course_id: course.id)
        assignment2 = create(:redlink, course_id: course.id)

        expect(assignment.id).to be_kind_of(Integer)
        expect(assignment2.article_id).to be_nil
      end

      it 'generates a sandbox_url by default' do
        course = create(:course)
        user = create(:user)
        article = create(:article)
        article_title = article.title
        assignment = create(:assignment, course: course, user: user,
                             article: article, article_title: article.title,
                             wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{user.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'uses an already existing sandbox URL for assignments with the same article' do
        course = create(:course)
        user = create(:user)
        article = create(:article)
        article_title = article.title

        # Another classmate is assigned that article first
        classmate = create(:user, username: 'ClassmateUsername')
        create(:assignment, course: course, user: classmate,
                article: article, article_title: article_title, wiki_id: 1)

        assignment = create(:assignment, course: course, user: user,
                             article: article, article_title: article_title,
                             wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{classmate.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'generates a sandbox_url for new articles' do
        course = create(:course)
        user = create(:user)
        article_title = 'New_Article'
        assignment = create(:assignment, course: course, user: user,
                             article_title: article_title, wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{user.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end
    end

    context 'when the same article on a different wiki is assignment' do
      let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }

      before do
        create(:assignment, user_id: 1, course_id: 1, wiki_id: 1,
                            article_title: 'Selfie', role: 0)
      end

      it 'creates the new assignment' do
        described_class.create(user_id: 1, course_id: 1, wiki_id: es_wiki.id,
                               article_title: 'Selfie', role: 0)
        expect(described_class.count).to eq(2)
      end
    end

    context 'when the same article is assignment twice' do
      before do
        create(:assignment, user_id: 1, course_id: 1, wiki_id: 1,
                            article_title: 'Selfie', role: 0)
      end

      let(:subject) do
        described_class.create!(user_id: 1, course_id: 1, wiki_id: 1,
                                article_title: 'Selfie', role: 0)
      end

      it 'does not create a duplicate' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
