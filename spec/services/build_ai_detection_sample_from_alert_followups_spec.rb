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

  it 'adds alerted edits with a follow-up, recording the self-report without trusting it' do
    alert(301, ['', 'false_positive'])
    alert(302, ['generate_text'])
    alert(303, nil)

    builder = described_class.new(sample_name: 'followups')

    units = builder.created.index_by(&:rev_id)
    expect(units.keys).to contain_exactly(301, 302)
    expect(units.values.map(&:ground_truth)).to all(be_nil)
    expect(units.values.map(&:provenance)).to all(eq('self_report'))
    expect(units[301]).to have_attributes(article_id: article.id, course_id: course.id,
                                          diff_mode: true, from_rev_id: nil)
    expect(units[301].metadata).to include('ai_how_used' => ['false_positive'],
                                           'self_reported_false_positive' => true)
    expect(units[302].metadata).to include('self_reported_false_positive' => false)
    expect(units[301].metadata['alert_id']).to be_present
  end
end
