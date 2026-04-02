# frozen_string_literal: true

require 'rails_helper'

describe AiEditAlert do
  # Representative Wikipedia page titles for each page_type branch,
  # ordered to match the case statement in page_type.
  page_type_examples = [
    { title: 'User:Ragesoss/Choose an Article',         type: :choose_an_article   },
    { title: 'User:Ragesoss/Evaluate an Article',       type: :evaluate_an_article },
    { title: 'User:Ragesoss/Sandbox/Bibliography',      type: :bibliography        },
    { title: 'User:Ragesoss/Artwork title/Outline',     type: :outline             },
    { title: 'User:Ragesoss/Peer Review',               type: :peer_review         },
    { title: 'User:Ragesoss/Sandbox',                   type: :sandbox             },
    { title: 'Draft:Artwork title',                     type: :draft               },
    { title: 'Talk:Artwork title',                      type: :talk_page           },
    { title: 'User talk:Ragesoss',                      type: :user_talk           },
    { title: 'Template talk:WikiProject Medicine',      type: :template_talk       },
    { title: 'Artwork title',                           type: :mainspace           },
    { title: 'Wikipedia:Some page',                     type: :unknown             }
  ]

  def build_alert(article_title)
    AiEditAlert.new(details: {
      article_title:,
      pangram_prediction: 'We are confident that this document is fully AI-generated',
      headline_result: 'Fully AI Generated',
      average_ai_likelihood: 0.97,
      max_ai_likelihood: 1.0,
      fraction_ai_content: 1.0,
      fraction_mixed_content: 0.0,
      predicted_ai_window_count: 3,
      pangram_share_link: 'https://www.pangram.com/history/example',
      prior_alert_count_for_course: 0
    })
  end

  describe '#page_type' do
    page_type_examples.each do |example|
      it "returns :#{example[:type]} for '#{example[:title]}'" do
        alert = build_alert(example[:title])
        expect(alert.page_type).to eq(example[:type])
      end
    end
  end

  describe '#advice_email_type' do
    it 'returns :exercise for exercise page types' do
      %w[
        User:Ragesoss/Choose\ an\ Article
        User:Ragesoss/Evaluate\ an\ Article
        User:Ragesoss/Artwork\ title/Outline
      ].each do |title|
        expect(build_alert(title).advice_email_type).to eq(:exercise)
      end
    end

    it 'returns :sandbox for sandbox page types' do
      expect(build_alert('User:Ragesoss/Sandbox').advice_email_type).to eq(:sandbox)
    end

    it 'returns :mainspace for mainspace page types' do
      expect(build_alert('Artwork title').advice_email_type).to eq(:mainspace)
    end

    it 'returns nil for other page types' do
      other_titles = ['Draft:Artwork title', 'Talk:Artwork title',
                      'User:Ragesoss/Sandbox/Bibliography']
      other_titles.each do |title|
        expect(build_alert(title).advice_email_type).to be_nil
      end
    end
  end

  describe 'accessor methods' do
    it 'returns pangram fields from the details hash' do
      alert = build_alert('Artwork title')
      full_prediction = 'We are confident that this document is fully AI-generated'
      expect(alert.pangram_prediction).to eq(full_prediction)
      expect(alert.average_ai_likelihood).to eq(0.97)
      expect(alert.max_ai_likelihood).to eq(1.0)
      expect(alert.predicted_llm).to be_nil
    end
  end
end
