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

    context 'for newly added category' do
      let(:category) { create(:category, name: 'Sports') }
      let(:course) { create(:course) }

      it 'updates the category' do
        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
          expect(described_class.last.article_titles).not_to be_empty
        end
      end
    end

    context 'for category updated more than one day ago' do
      let(:category) do
        create(:category, name: 'Films', created_at: 5.days.ago, updated_at: 2.days.ago)
      end
      let(:course) { create(:course) }

      it 'updates the category' do
        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
          expect(described_class.last.updated_at > 30.seconds.ago).to eq(true)
        end
      end
    end

    context 'for category updated less than one day ago' do
      let(:category) do
        create(:category, name: 'Animals', created_at: 5.days.ago, updated_at: 12.hours.ago)
      end
      let(:course) { create(:course) }

      it 'does not update the category' do
        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
          expect(described_class.last.updated_at <= 12.hours.ago).to eq(true)
        end
      end
    end

    context 'for category-source Category' do
      let(:category) { create(:category, name: 'Homo sapiens fossils') }
      let(:course) { create(:course) }
      let!(:article) { create(:article, title: 'Manot_1') }

      it 'updates article titles for categories associated with courses' do
        expect(described_class.last.article_titles).to be_empty

        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
          expect(described_class.last.article_titles).not_to be_empty
          expect(described_class.last.article_ids).to include(article.id)
        end
      end
    end

    context 'for psid-source Category' do
      let(:category) { create(:category, name: 9964305, source: 'psid') }
      let(:course) { create(:course) }
      let!(:article) { create(:article, title: 'A cappella') }

      it 'updates article titles for categories associated with courses' do
        # Pending is used here to make sure that the build passes when PetScan is down
        pending 'Fails when PetScan is down.'
        expect(described_class.last.article_titles).to be_empty

        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
          expect(described_class.last.article_titles).not_to be_empty
          expect(described_class.last.article_ids).to include(article.id)
        end
        pass_pending_spec
      end

      it 'fails gracefully when PetScan is unreachable' do
        expect_any_instance_of(PetScanApi).to receive(:petscan).and_raise(Errno::EHOSTUNREACH)
        described_class.refresh_categories_for(course)
        expect(described_class.last.article_ids).to be_empty
      end
    end

    # Pagepile is a tool for representing a static list of articles —
    # both existing and not — on a single wiki: https://pagepile.toolforge.org/
    context 'for pileid-source Category' do
      # Example pile from `lawiktionary`: https://pagepile.toolforge.org/api.php?action=get_data&format=json&id=28301
      let(:category) { create(:category, name: 28301, source: 'pileid') }
      let(:course) { create(:course) }
      let(:lawiktionary) { Wiki.get_or_create(language: 'la', project: 'wiktionary') }
      let(:article) { create(:article, wiki: lawiktionary, title: 'America') }

      it 'updates article titles and wiki for categories associated with courses' do
        expect(described_class.last.article_titles).to be_empty
        expect(described_class.last.wiki.language).to eq('en')

        VCR.use_cassette 'categories' do
          expect(article.wiki.language).to eq('la')
          described_class.refresh_categories_for(course)
          expect(described_class.last.article_titles).not_to be_empty
          expect(described_class.last.article_ids).to include(article.id)
          expect(described_class.last.wiki).to eq(lawiktionary)
        end
      end

      it 'fails gracefully when fetching a PagePile errors' do
        expect_any_instance_of(PagePileApi).to receive(:pagepile).and_raise(StandardError)
        expect(Raven).to receive(:capture_exception)
        described_class.refresh_categories_for(course)
        expect(described_class.last.article_titles).to be_empty
      end
    end

    context 'for template-source Category' do
      let(:category) { create(:category, name: 'Malaysia-sport-bio-stub', source: 'template') }
      let(:course) { create(:course) }
      let!(:article) { create(:article, title: 'Nur_Shazrin_Mohd_Latif') }

      it 'updates article titles for categories associated with courses' do
        expect(described_class.last.article_titles).to be_empty

        VCR.use_cassette 'categories' do
          described_class.refresh_categories_for(course)
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
