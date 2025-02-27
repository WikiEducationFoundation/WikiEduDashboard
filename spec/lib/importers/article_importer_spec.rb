# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe ArticleImporter do
  before { stub_wiki_validation }

  let(:en_wiki) { Wiki.default_wiki }
  let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }
  let(:kn_wiki) { create(:wiki, language: 'kn', project: 'wikipedia') }

  describe '.import_articles' do
    it 'creates an Article from a English Wikipedia page_id' do
      VCR.use_cassette 'article_importer/article_importer' do
        described_class.new(en_wiki).import_articles [46349871]
        article = Article.find_by(mw_page_id: 46349871)
        expect(article.title).to eq('Kostanay')
      end
    end

    it 'works for a language besides the default' do
      VCR.use_cassette 'article_importer/article_importer' do
        described_class.new(es_wiki).import_articles [100]
        article = Article.find_by(mw_page_id: 100)
        expect(article.title).to eq('Alnus')
      end
    end
  end

  describe '.import_articles_by_title' do
    it 'creates an Article from a title with the correct mw_page_id' do
      titles = %w[Selfie Bombus_hortorum Kostanay]
      VCR.use_cassette 'article_importer/existing_titles' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: 'Kostanay').mw_page_id).to eq(46349871)
    end

    it 'does not create an article if there is no matching title' do
      titles = ['There_is_no_article_with_this_title']
      VCR.use_cassette 'article_importer/nonexistent_title' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end

    it 'does not create an article if the title is invalid' do
      titles = ['Title_with_[illegal]_characters']
      VCR.use_cassette 'article_importer/invalid_title' do
        described_class.new(en_wiki).import_articles_by_title(titles)
      end
      expect(Article.find_by(title: titles[0])).to be_nil
    end

    it 'works for a language besides the default' do
      VCR.use_cassette 'article_importer/existing_titles' do
        titles = %w[Selfie Bombus_hortorum]
        described_class.new(es_wiki).import_articles_by_title(titles)
        expect(Article.find_by(title: 'Selfie').mw_page_id).to eq(6210294)
      end
    end

    it 'updates the title if the article with that mw_page_id exists already' do
      create(:article, title: 'Constantinople', mw_page_id: 3391396)
      VCR.use_cassette 'article_importer/collisions' do
        described_class.new(en_wiki).import_articles_by_title(['Istanbul'])
        expect(Article.find_by(title: 'Istanbul').mw_page_id).to eq(3391396)
      end
    end

    it 'returns the correct number of titles without raising error 414' do
      VCR.use_cassette 'article_importer/some_article_titles' do
        # Non-ASCII characters like those in the Kannada language shown
        # below use 2 to 4 bytes per character in UTF-8 compared to the
        # 1 byte of ASCII characters. If the titles below are appended
        # to a GET request url as a parameter, the error '414 request uri too long'
        # occurs. The fix is using a POST request instead and passing the titles
        # as parameters in the request body.
        titles = %w[
          ವಿಕಿಪೀಡಿಯ:ಬದಲಿ
          ವಿಕಿಪೀಡಿಯ:Talk_page_templates
          ವಿಕಿಪೀಡಿಯ:ಸ್ಪಾಯ್ಲರ್
          ವಿಕಿಪೀಡಿಯ:Revision_deletion
          ವಿಕಿಪೀಡಿಯ:Open_proxies
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಭಾರತೀಯ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಖಗೋಳ_ವಸ್ತುಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಪುಸ್ತಕಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಪ್ರಸಾರ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ರಸಾಯನಶಾಸ್ತ್ರ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಪಾದ್ರಿಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಕಾಮಿಕ್ಸ್)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಕಂಪನಿಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ದೇಶ-ನಿರ್ದಿಷ್ಟ_ವಿಷಯಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿನ_ಸಂಪ್ರದಾಯಗಳು_(ನಿರ್ದಿಷ್ಟ_ಅಥವಾ_ಅನಿರ್ದಿಷ್ಟ_ಲೇಖನ_ಹೆಸರಿನ_ಆರಂಭದಲ್ಲಿ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಜನಾಂಗೀಯಗಳು_ಮತ್ತು_ಬುಡಕಟ್ಟುಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಪ್ರಾಣಿ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಚಲನಚಿತ್ರಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಭೌಗೋಳಿಕ_ಹೆಸರುಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಸರ್ಕಾರ_ಮತ್ತು_ಕಾನೂನು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಐಸ್_ಹಾಕಿ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಭಾಷೆಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಕಾನೂನು_ಜಾರಿ_ಏಜೆನ್ಸಿ_ವರ್ಗಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಪಟ್ಟಿಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಹಸ್ತಪ್ರತಿಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಸಂಗೀತ)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಸಂಖ್ಯೆಗಳು_ಮತ್ತು_ದಿನಾಂಕಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಜನರು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ಬಹುವಚನಗಳು)
          ವಿಕಿಪೀಡಿಯ:ಹೆಸರಿಸುವ_ಸಂಪ್ರದಾಯಗಳು_(ರಾಜಕೀಯ_ಪಕ್ಷಗಳು)
        ]

        described_class.new(kn_wiki).import_articles_by_title(titles)

        response = VCR.current_cassette.serializable_hash.dig('http_interactions', 0, 'response')
        expect(response['status']['code']).not_to eq(414)

        # Multiple titles could belong to a single article
        # so count number of titles instead of articles
        title_count_in_response = response['body']['string'].scan(/"title":/).count
        expect(title_count_in_response).to eq(titles.count)
      end
    end
  end

  describe '.import_articles_from_revision_data' do
    let(:revision_data) do
      [{ 'mw_page_id' => '69830902', 'wiki_id' => 5, 'title' => 'Ar00', 'namespace' => '2' },
       { 'mw_page_id' => '69830903', 'wiki_id' => 5, 'title' => 'Any title', 'namespace' => '1' }]
    end

    it 'creates all the Article records' do
      VCR.use_cassette 'article_importer/article_importer' do
        expect(Article.find_by(mw_page_id: 69830902)).to be_nil
        expect(Article.find_by(mw_page_id: 69830903)).to be_nil
        described_class.new(es_wiki).import_articles_from_revision_data revision_data
        article_1 = Article.find_by(mw_page_id: 69830902)
        expect(article_1.title).to eq('Ar00')
        expect(article_1.wiki_id).to eq(5)
        expect(article_1.namespace).to eq(2)
        article_2 = Article.find_by(mw_page_id: 69830903)
        expect(article_2.title).to eq('Any title')
        expect(article_2.wiki_id).to eq(5)
        expect(article_2.namespace).to eq(1)
      end
    end
  end
end
