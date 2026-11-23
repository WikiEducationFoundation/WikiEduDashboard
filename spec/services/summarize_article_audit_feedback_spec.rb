# frozen_string_literal: true

require 'rails_helper'

describe SummarizeArticleAuditFeedback do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:audit) { ArticleAudit.create!(wiki:, mw_rev_id: 123, article_title: 'Acme') }
  let(:first_user) { create(:admin) }
  let(:second_user) { create(:admin, username: 'Second') }
  let(:tone) do
    audit.check_results.create!(check_key: 'tone', status: 'succeeded',
                                findings: [{ 'title' => 'Peacock' }, { 'title' => 'Weasel' }])
  end
  let(:lead) do
    audit.check_results.create!(check_key: 'lead_section', status: 'succeeded',
                                findings: [{ 'code' => 'too_long' }, { 'code' => 'missing' }])
  end
  let(:summary) { described_class.new }

  def feedback(result, index, user, **answers)
    result.finding_feedbacks.create!(finding_index: index, user:, **answers)
  end

  it 'groups LLM findings by check and code findings by check and code' do
    feedback(tone, 0, first_user, accurate: 'yes')
    feedback(tone, 1, first_user, accurate: 'no')
    feedback(tone, 0, second_user, accurate: 'partly', show_to_participants: 'maybe')
    feedback(lead, 0, first_user, show_to_participants: 'yes')
    feedback(lead, 1, first_user, show_to_participants: 'no')

    expect(summary.groups.map { |group| group.values_at(:check_key, :code, :responses) })
      .to eq([['lead_section', 'missing', 1], ['lead_section', 'too_long', 1], ['tone', nil, 3]])
    tone_group = summary.groups.last
    expect(tone_group[:accurate]).to eq('yes' => 1, 'partly' => 1, 'no' => 1)
    expect(tone_group[:show_to_participants]).to eq('yes' => 0, 'maybe' => 1, 'no' => 0)
  end

  it 'lists each response with its finding' do
    feedback(tone, 1, first_user, accurate: 'no', accurate_comment: 'Not weaselly')
    expect(summary.responses).to contain_exactly(
      a_hash_including(audit_id: audit.id, article_title: 'Acme', check_key: 'tone',
                       title: 'Weasel', finding_id: "#{tone.id}-1", user: first_user.username,
                       accurate: 'no', accurate_comment: 'Not weaselly')
    )
  end
end
