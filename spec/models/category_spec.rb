# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id             :bigint(8)        not null, primary key
#  wiki_id        :integer
#  article_titles :text(16777215)
#  name           :string(255)
#  depth          :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source         :string(255)      default("category")
#

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe '.refresh_categories_for' do
    before do
      course.categories << category
    end

    context 'for category-source Category' do
      let(:category) { create(:category, name: 'Homo sapiens fossils') }
      let(:course) { create(:course) }
      let!(:article) { create(:article, title: 'Manot_1') }

      it 'updates article titles for categories associated with courses' do
        expect(described_class.last.article_titles).to be_empty

        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(Course.all)
          expect(described_class.last.article_titles).not_to be_empty
          expect(described_class.last.article_ids).to include(article.id)
        end
      end
    end

    context 'for template-source Category' do
      let(:category) { create(:category, name: 'Malaysia-sport-bio-stub', source: 'template') }
      let(:course) { create(:course) }
      let!(:article) { create(:article, title: 'Nur_Shazrin_Mohd_Latif') }

      it 'updates article titles for categories associated with courses' do
        expect(described_class.last.article_titles).to be_empty

        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(Course.all)
          expect(described_class.last.article_titles).not_to be_empty
          expect(described_class.last.article_ids).to include(article.id)
        end
      end
    end
  end

  context 'when the requested page is missing' do
    let(:mr_wiki) { create(:wiki, language: 'mr', project: 'wikipedia') }
    let(:category) do
      # This is a template that mistakenly includes the localized template prefix,
      # so it ends up double-prefixed in the search, and is thus not found.
      create(:category, name: 'साचा:स्वातंत्र्यलढा_अभियान_२०१८',
                        wiki: mr_wiki, source: 'template')
    end

    before do
      stub_wiki_validation
    end

    it 'works without error' do
      VCR.use_cassette 'categories/mr_wiki' do
        category.refresh_titles
        expect(category.article_titles).to eq([])
      end
    end
  end
end
