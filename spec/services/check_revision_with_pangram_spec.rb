# frozen_string_literal: true

require 'rails_helper'

describe CheckRevisionWithPangram do
  let(:en_wiki) { Wiki.default_wiki }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  # Based on https://en.wikipedia.org/w/index.php?title=User:100110Z/Five-a-side_football&oldid=1327139425
  let(:simplified_pangram_response) do
    { 'stage' => 'STAGE_SUCCESS',
      'text' => 'example',
      'version' => '4.0',
      'headline' => 'AI Generated',
      'prediction' => 'We believe that this entire text is AI.',
      'prediction_short' => 'AI',
      'fraction_ai' => 1.0,
      'fraction_ai_assisted' => 0.0,
      'fraction_human' => 0.0,
      'num_ai_segments' => 3,
      'num_ai_assisted_segments' => 0,
      'num_human_segments' => 0,
      'windows' =>
        [{ 'text' => 'first window',
           'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0,
           'confidence' => 'High',
           'start_index' => 0,
           'end_index' => 2281,
           'word_count' => 359,
           'token_length' => 483,
           'is_humanized' => false,
           'humanizer_score' => 0.00444 },
         { 'text' => 'second window',
           'label' => 'AI-Generated',
           'ai_assistance_score' => 0.9982278487261604,
           'confidence' => 'High',
           'start_index' => 2281,
           'end_index' => 4737,
           'word_count' => 358,
           'token_length' => 476,
           'is_humanized' => false,
           'humanizer_score' => 0.0021 },
         { 'text' => 'third window',
           'label' => 'AI-Generated',
           'ai_assistance_score' => 0.9959831237792969,
           'confidence' => 'High',
           'start_index' => 4737,
           'end_index' => 5202,
           'word_count' => 72,
           'token_length' => 94,
           'is_humanized' => false,
           'humanizer_score' => 0.0 }],
      'dashboard_link' => 'https://www.pangram.com/history/7980768b-0b15-4d42-ad62-30ba8cf0e92f' }
  end
  let(:stored_simplified_pangram_response) do
    { 'stage' => 'STAGE_SUCCESS',
      'version' => '4.0',
      'headline' => 'AI Generated',
      'prediction' => 'We believe that this entire text is AI.',
      'prediction_short' => 'AI',
      'fraction_ai' => 1.0,
      'fraction_ai_assisted' => 0.0,
      'fraction_human' => 0.0,
      'num_ai_segments' => 3,
      'num_ai_assisted_segments' => 0,
      'num_human_segments' => 0,
      'windows' =>
        [{ 'label' => 'AI-Generated',
           'ai_assistance_score' => 1.0,
           'confidence' => 'High',
           'start_index' => 0,
           'end_index' => 2281,
           'word_count' => 359,
           'token_length' => 483,
           'is_humanized' => false,
           'humanizer_score' => 0.00444 },
         { 'label' => 'AI-Generated',
           'ai_assistance_score' => 0.9982278487261604,
           'confidence' => 'High',
           'start_index' => 2281,
           'end_index' => 4737,
           'word_count' => 358,
           'token_length' => 476,
           'is_humanized' => false,
           'humanizer_score' => 0.0021 },
         { 'label' => 'AI-Generated',
           'ai_assistance_score' => 0.9959831237792969,
           'confidence' => 'High',
           'start_index' => 4737,
           'end_index' => 5202,
           'word_count' => 72,
           'token_length' => 94,
           'is_humanized' => false,
           'humanizer_score' => 0.0 }],
      'dashboard_link' => 'https://www.pangram.com/history/7980768b-0b15-4d42-ad62-30ba8cf0e92f' }
  end
  let(:timestamp) { 5.minutes.ago.to_i }

  let!(:live_article) do
    create(:article, title: '3M_contamination_of_Minnesota_groundwater',
                     mw_page_id: 68907377)
  end
  # https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891
  let(:live_article_revision_id) { 1315795891 }

  context 'when it is the first revision' do
    # https://en.wikipedia.org/w/index.php?title=User:Resekorynta/Evaluate_an_Article&oldid=1315967896
    let!(:sandbox_article) do
      create(:article, namespace: Article::Namespaces::USER,
                       title: 'Resekorynta/Evaluate_an_Article',
                       mw_page_id: 81301594)
    end
    let(:sandbox_creation_revision_id) { 1315967896 }

    it 'fetches the page HTML and checks based on that' do
      expect(AiEditAlert.count).to eq(0)
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_parent_revision_id)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_revision_html)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:generate_plaintext_from_html)
                                                  .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_pangram_inference).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_alert).and_call_original
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram' do
        described_class.new(
          { 'mw_rev_id' => sandbox_creation_revision_id,
           'wiki_id' => en_wiki.id,
           'article_id' => sandbox_article.id,
           'course_id' => course.id,
           'user_id' => user.id,
           'revision_timestamp' => timestamp }
        )
      end
      expect(AiEditAlert.count).to eq(1)
      expect(AiEditAlert.last.article_id).to eq(sandbox_article.id)

      expect(RevisionAiScore.count).to eq(1)
      expect(RevisionAiScore.last.article_id).to eq(sandbox_article.id)
      expect(RevisionAiScore.last.details).to eq(stored_simplified_pangram_response)
      expect(RevisionAiScore.last.check_type).to eq('Pangram 4')
      expect(RevisionAiScore.last.check_origin).to eq('course_update')
    end
  end

  context 'when there is a parent revision' do
    it 'fetches the diff table and checks based on that' do
      expect(AiEditAlert.count).to eq(0)
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_parent_revision_id)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_diff_table)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:generate_wikitext_from_diff_table)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_parsed_changed_wikitext)
                                                  .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_pangram_inference).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_alert).and_call_original
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram_2' do
        described_class.new(
          { 'mw_rev_id' => live_article_revision_id,
            'wiki_id' => en_wiki.id,
            'article_id' => live_article.id,
            'course_id' => course.id,
            'user_id' => user.id,
            'revision_timestamp' => timestamp }
        )
      end
      expect(AiEditAlert.count).to eq(1)
      expect(AiEditAlert.last.article_id).to eq(live_article.id)

      expect(RevisionAiScore.count).to eq(1)
      expect(RevisionAiScore.last.article_id).to eq(live_article.id)
      expect(RevisionAiScore.last.avg_ai_likelihood).to be_between(0, 1)
      expect(RevisionAiScore.last.max_ai_likelihood).to eq(1.0)
      expect(RevisionAiScore.last.details).to eq(stored_simplified_pangram_response)
      expect(RevisionAiScore.last.check_type).to eq('Pangram 4')
      expect(RevisionAiScore.last.check_origin).to eq('course_update')
    end
  end

  context 'when there are prior alerts for the same page and user' do
    let!(:prior_page_alert) { create(:ai_edit_alert, course:, article: live_article) }
    let!(:prior_user_alert) { create(:ai_edit_alert, course:, user:, created_at: 2.days.ago) }

    it 'records prior alert IDs in the new alert details' do
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram_2' do
        described_class.new(
          { 'mw_rev_id' => live_article_revision_id,
            'wiki_id' => en_wiki.id,
            'article_id' => live_article.id,
            'course_id' => course.id,
            'user_id' => user.id,
            'revision_timestamp' => timestamp }
        )
      end
      new_alert = AiEditAlert.last
      expect(new_alert.details[:prior_alert_for_page]).to eq(prior_page_alert.id)
      expect(new_alert.details[:prior_alert_for_user]).to eq(prior_user_alert.id)
    end
  end

  context 'when the revision more than 2 weeks old' do
    let(:timestamp) { 15.days.ago.to_i }

    it 'does not create an alert' do
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)
      VCR.use_cassette 'pangram_2' do
        described_class.new(
          { 'mw_rev_id' => live_article_revision_id,
           'wiki_id' => en_wiki.id,
           'article_id' => live_article.id,
           'course_id' => course.id,
           'user_id' => user.id,
           'revision_timestamp' => timestamp }
        )
      end
      expect(AiEditAlert.count).to eq(0)
    end
  end

  context 'when the revision is missing or deleted' do
    let(:missing_revision_id) { 999999999999 }
    let(:article) { create(:article) }

    it 'logs a message to Sentry and exits gracefully' do
      expect(Sentry).to receive(:capture_message)
        .with("WikiApi::ArticleContent: revision #{missing_revision_id} missing or deleted")
      expect_any_instance_of(GetRevisionPlaintext).not_to receive(:fetch_diff_table)
      expect_any_instance_of(GetRevisionPlaintext).not_to receive(:fetch_revision_html)

      VCR.use_cassette 'pangram_missing_revision' do
        described_class.new(
          { 'mw_rev_id' => missing_revision_id,
           'wiki_id' => en_wiki.id,
           'article_id' => article.id,
           'course_id' => course.id,
           'user_id' => user.id,
           'revision_timestamp' => timestamp }
        )
      end
    end
  end

  context 'when the revision was already checked' do
    let!(:live_article) do
      create(:article, title: '3M_contamination_of_Minnesota_groundwater',
                       mw_page_id: 68907377)
    end
    let!(:revision_ai_score) do
      create(:revision_ai_score, revision_id: live_article_revision_id,
             wiki_id: en_wiki.id, course:, user:, article: live_article,
             details: stored_simplified_pangram_response, avg_ai_likelihood: 0.5,
             check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN)
    end
    let(:attrs) do
      { 'mw_rev_id' => live_article_revision_id,
        'wiki_id' => en_wiki.id,
        'article_id' => live_article.id,
        'course_id' => course.id,
        'user_id' => user.id,
        'revision_timestamp' => timestamp }
    end

    it 'returns prematurely if the record is found' do
      expect_any_instance_of(described_class).not_to receive(:check)

      described_class.new(
        { 'mw_rev_id' => live_article_revision_id,
         'wiki_id' => en_wiki.id,
         'article_id' => live_article.id,
         'course_id' => course.id,
         'user_id' => user.id,
         'revision_timestamp' => timestamp }
      )
    end

    it 'checks the revision again if nil avg_ai_likelihood' do
      revision_ai_score.update(avg_ai_likelihood: nil)
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_parent_revision_id)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_diff_table).and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:generate_wikitext_from_diff_table)
                                                  .and_call_original
      expect_any_instance_of(GetRevisionPlaintext).to receive(:fetch_parsed_changed_wikitext)
                                                  .and_call_original
      expect_any_instance_of(described_class).to receive(:fetch_pangram_inference).and_call_original
      expect_any_instance_of(described_class).to receive(:generate_alert).and_call_original
      expect_any_instance_of(PangramApi).to receive(:inference)
                                        .and_return(simplified_pangram_response)

      VCR.use_cassette 'pangram_2' do
        described_class.new(
          { 'mw_rev_id' => live_article_revision_id,
           'wiki_id' => en_wiki.id,
           'article_id' => live_article.id,
           'course_id' => course.id,
           'user_id' => user.id,
           'revision_timestamp' => timestamp }
        )
      end

      expect(RevisionAiScore.count).to eq(2)
      expect(RevisionAiScore.last.avg_ai_likelihood).not_to be_nil
    end

    it 'still counts as checked when the row is from an earlier detector' do
      revision_ai_score.update(check_type: RevisionAiScore::PANGRAM_V3_KEY)
      expect_any_instance_of(described_class).not_to receive(:check)

      described_class.new(attrs)
    end

    it 'still counts as checked when the row predates the check_origin field' do
      revision_ai_score.update(check_origin: nil)
      expect_any_instance_of(described_class).not_to receive(:check)

      described_class.new(attrs)
    end

    it 'ignores a detector comparison row, which production never scored' do
      revision_ai_score.update(check_origin: RevisionAiScore::DETECTOR_COMPARISON_ORIGIN)
      expect_any_instance_of(described_class).to receive(:check)

      described_class.new(attrs)
    end

    it 'ignores an admin AI tools row' do
      revision_ai_score.update(check_origin: RevisionAiScore::AI_TOOL_ORIGIN)
      expect_any_instance_of(described_class).to receive(:check)

      described_class.new(attrs)
    end
  end

  context 'when the detector call fails' do
    let(:attrs) do
      { 'mw_rev_id' => live_article_revision_id,
        'wiki_id' => en_wiki.id,
        'article_id' => live_article.id,
        'course_id' => course.id,
        'user_id' => user.id,
        'revision_timestamp' => timestamp }
    end

    it 'records the failure without retrying a request the API refused' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(402, 'out of credit'))

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.not_to raise_error
      end

      score = RevisionAiScore.last
      expect(score.avg_ai_likelihood).to be_nil
      expect(score.check_type).to eq('Pangram 4')
      expect(score.check_origin).to eq('course_update')
      expect(score.details['error']).to eq('PangramApi::RequestError')
    end

    it 'records the failure without retrying a task the API failed' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::TaskFailed, 'task 1 failed')

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.not_to raise_error
      end

      expect(RevisionAiScore.last.details['error']).to eq('PangramApi::TaskFailed')
    end

    it 're-raises a timeout so the worker retries it' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::TaskTimeout, 'task 1 unfinished after 60s')

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::TaskTimeout)
      end

      expect(RevisionAiScore.last.avg_ai_likelihood).to be_nil
    end

    it 're-raises a server error so the worker retries it' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(503, 'unavailable'))

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::RequestError)
      end

      expect(RevisionAiScore.last.avg_ai_likelihood).to be_nil
    end

    it 'does not generate an alert' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(402, 'out of credit'))

      VCR.use_cassette 'pangram_2' do
        described_class.new(attrs)
      end

      expect(AiEditAlert.count).to eq(0)
    end

    it 'updates the one failed row rather than adding another' do
      allow_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(402, 'out of credit'))

      VCR.use_cassette 'pangram_2' do
        described_class.new(attrs)
        described_class.new(attrs)
      end

      expect(RevisionAiScore.count).to eq(1)
    end

    it 'leaves the revision open to a later successful check' do
      allow_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(402, 'out of credit'))

      VCR.use_cassette 'pangram_2' do
        described_class.new(attrs)

        allow_any_instance_of(PangramApi).to receive(:inference)
          .and_return(simplified_pangram_response)
        described_class.new(attrs)
      end

      expect(RevisionAiScore.where.not(avg_ai_likelihood: nil).count).to eq(1)
    end

    it 'scores over the failure row rather than adding a second row' do
      allow_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::TaskTimeout, 'task 1 unfinished after 60s')

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::TaskTimeout)

        allow_any_instance_of(PangramApi).to receive(:inference)
          .and_return(simplified_pangram_response)
        described_class.new(attrs)
      end

      expect(RevisionAiScore.count).to eq(1)
      expect(RevisionAiScore.last.avg_ai_likelihood).not_to be_nil
    end

    it 're-raises a rate limit so the worker retries it' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(429, 'too many requests'))

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::RequestError)
      end
    end

    it 're-raises a request timeout so the worker retries it' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(408, 'request timeout'))

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::RequestError)
      end
    end

    it 'reports a terminal failure to Sentry, which nothing else would surface' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(402, 'out of credit'))
      expect(Sentry).to receive(:capture_exception)
        .with(instance_of(PangramApi::RequestError), hash_including(level: 'warning'))

      VCR.use_cassette 'pangram_2' do
        described_class.new(attrs)
      end
    end

    it 'does not report a retryable failure to Sentry, which Sidekiq reports' do
      expect_any_instance_of(PangramApi).to receive(:inference)
        .and_raise(PangramApi::RequestError.new(503, 'unavailable'))
      expect(Sentry).not_to receive(:capture_exception)

      VCR.use_cassette 'pangram_2' do
        expect { described_class.new(attrs) }.to raise_error(PangramApi::RequestError)
      end
    end
  end

  context 'when the revision has empty plain text' do
    let!(:article) do
      create(:article, title: 'محمد_أمين_الطرابلسي/sandbox3',
                       mw_page_id: 76107536)
    end
    let(:revision_id) { 1318180742 }

    it 'does not fail' do
      VCR.use_cassette 'pangram_empty_plain_text' do
        expect_any_instance_of(described_class).not_to receive(:fetch_pangram_inference)

        described_class.new(
          { 'mw_rev_id' => revision_id,
           'wiki_id' => en_wiki.id,
           'article_id' => article.id,
           'course_id' => course.id,
           'user_id' => user.id,
           'revision_timestamp' => timestamp }
        )
      end
    end
  end
end
