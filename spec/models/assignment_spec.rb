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
#  flags         :text(65535)
#

require 'rails_helper'

describe Assignment do
  before { stub_wiki_validation }

  let(:course) { create(:course) }

  describe 'assignment creation' do
    context 'when no similar assignments exist' do
      it 'creates Assignment objects' do
        assignment = create(:assignment, course_id: course.id)
        assignment2 = create(:redlink, course_id: course.id)

        expect(assignment.id).to be_kind_of(Integer)
        expect(assignment2.article_id).to be_nil
      end

      it 'generates a sandbox_url by default' do
        user = create(:user)
        article = create(:article)
        article_title = article.title
        assignment = create(:assignment, course:, user:,
                             article:, article_title: article.title,
                             wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{user.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'generates a sandbox_url if no language is defined' do
        wiki = create(:wiki, language: nil, project: 'wikidata')
        user = create(:user)
        article = create(:article)
        article_title = article.title
        assignment = create(:assignment, course:, user:,
                             article:, article_title: article.title,
                             wiki:)

        base_url = 'https://www.wikidata.org/wiki'
        expected = "#{base_url}/User:#{user.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'uses an already existing sandbox URL for assignments with the same article' do
        user = create(:user)
        article = create(:article)
        article_title = article.title

        # Another classmate is assigned that article first
        classmate = create(:user, username: 'ClassmateUsername')
        create(:assignment, course:, user: classmate,
                article:, article_title:, wiki_id: 1)

        assignment = create(:assignment, course:, user:,
                             article:, article_title:,
                             wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{classmate.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'generates a sandbox_url for new articles' do
        user = create(:user)
        article_title = 'New_Article'
        assignment = create(:assignment, course:, user:,
                             article_title:, wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        expected = "#{base_url}/User:#{user.username}/#{article_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'generates a working sandbox_url for article ending in "?"' do
        user = create(:user)
        article = create(:article, title: 'Brown_Bear,_Brown_Bear,_What_Do_You_See?')
        assignment = create(:assignment, course:, user:,
                             article:, article_title: article.title,
                             wiki_id: 1)

        base_url = "https://#{assignment.wiki.language}.#{assignment.wiki.project}.org/wiki"
        encoded_title = 'Brown_Bear%2C_Brown_Bear%2C_What_Do_You_See%3F'
        expected = "#{base_url}/User:#{user.username}/#{encoded_title}"
        expect(assignment.sandbox_url).to eq(expected)
      end

      it 'returns a #sandbox_pagename for a username that ends in "%"' do
        user = create(:user, username: 'DocKaryme28%')
        assignment = create(:assignment, user:, article_title: 'Plague_of_Athens')
        expected = 'User:DocKaryme28%/Plague_of_Athens'
        expect(assignment.sandbox_pagename).to eq(expected)
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

    def create_with_title(title)
      described_class.create(user_id: 1, course_id: 1, wiki_id: 1, role: 0, article_title: title)
    end

    context 'when the title is not valid' do
      it 'disallows braces' do
        title = 'My Title {{italicized}}'
        expect(create_with_title(title).valid?).to eq(false)
      end

      it 'disallows square brackets' do
        title = '[[My Title]]'
        expect(create_with_title(title).valid?).to eq(false)
      end

      it 'disallows angle brackets' do
        title = 'Arthur_smithies_-_Proud_Prophet_>_Thomas_Schelling'
        expect(create_with_title(title).valid?).to eq(false)
      end

      it 'disallows tabs' do
        title = "•\tWartime_sexual_violence"
        expect(create_with_title(title).valid?).to eq(false)
      end

      it 'disallows special pages' do
        title = 'Special:Contributions/Evanschwartz'
        expect(create_with_title(title).valid?).to eq(false)
      end

      it 'disallows leading colons' do
        title = ':es:Plan_de_Acci%C3%B3n_Conjunto_y_Completo_'
        expect(create_with_title(title).valid?).to eq(false)
      end
    end
  end
end
