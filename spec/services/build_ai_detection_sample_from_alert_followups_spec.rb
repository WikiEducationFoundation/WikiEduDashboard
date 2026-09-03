# frozen_string_literal: true

require 'rails_helper'

describe BuildAiDetectionSampleFromAlertFollowups do
  let(:text) { (['Prose the student added in the flagged edit.'] * 60).join(' ') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:article) { create(:article, wiki_id: enwiki.id) }
  let(:student) { create(:user, username: 'Student') }

  def alert(rev_id, answers)
    alert = AiEditAlert.create!(user: student, course:, article:, revision_id: rev_id,
                                details: { article_title: article.title })
    if answers
      alert.details["followup_#{student.username}"] = { AI_how_used: answers,
                                                        timestamp: Time.zone.now }
      alert.save!
    end
    alert
  end

  before do
    allow(GetRevisionPlaintext).to receive(:new)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: text))
  end

  it 'adds alerted edits with a follow-up, using the self-report as ground truth' do
    alert(301, ['', 'false_positive'])
    alert(302, ['generate_text'])
    alert(303, ['other'])
    alert(304, nil)

    builder = described_class.new(sample_name: 'followups')

    units = builder.created.index_by(&:rev_id)
    expect(units.keys).to contain_exactly(301, 302, 303)
    expect(units[301].ground_truth).to eq('self_reported_no_ai')
    expect(units[302].ground_truth).to eq('self_reported_ai')
    expect(units[303].ground_truth).to eq('unknown')
    expect(units[301]).to have_attributes(article_id: article.id, course_id: course.id,
                                          diff_mode: true, from_rev_id: nil)
    expect(units[301].metadata).to include('ai_how_used' => ['false_positive'])
    expect(units[301].metadata['alert_id']).to be_present
  end
end
