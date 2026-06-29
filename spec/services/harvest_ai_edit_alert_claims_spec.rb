# frozen_string_literal: true

require 'rails_helper'

describe HarvestAiEditAlertClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, subject: 'Ecology') }
  let(:article) do
    create(:article, wiki:, title: 'Sea otter', namespace: Article::Namespaces::MAINSPACE)
  end
  let(:student) { create(:user) }

  # The added side of the flagged diff: one cited sentence.
  let(:diff_html) do
    <<~HTML
      <p>Sea otters use rocks as tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Riedman 1990</a></cite></span></li></ol>
    HTML
  end

  let(:alert) do
    create(:ai_edit_alert, course:, article:, user: student, revision_id: 777,
                           details: { article_title: 'Sea otter' })
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: diff_html,
                                  revision_timestamp: '2025-12-14T04:53:46Z'))
  end

  it 'harvests the claims added in the flagged revision into the pool' do
    expect { described_class.new(alert) }.to change(VerificationClaim, :count).by(1)
  end

  it 'renders the added content of the flagged revision (diff against parent)' do
    described_class.new(alert)
    expect(GetRevisionHtmlWithCitations).to have_received(:new).with(777, wiki, diff_mode: true)
  end

  it 'tags entries with the alert, source course, subject, revision and student' do
    described_class.new(alert)
    claim = VerificationClaim.last
    expect([claim.alert_id, claim.source_course_id, claim.subject, claim.mw_rev_id,
            claim.article_id]).to eq([alert.id, course.id, 'Ecology', 777, article.id])
    expect(claim.courses_user.user_id).to eq(student.id)
    expect(claim.mw_rev_timestamp).to eq(Time.utc(2025, 12, 14, 4, 53, 46))
  end

  it 'is idempotent when the same alert is harvested again' do
    described_class.new(alert)
    expect { described_class.new(alert) }.not_to change(VerificationClaim, :count)
  end

  it 'skips alerts that are not mainspace, without calling the wiki' do
    draft = create(:ai_edit_alert, course:, article:, revision_id: 778,
                                   details: { article_title: 'Draft:Sea otter' })
    expect { described_class.new(draft) }.not_to change(VerificationClaim, :count)
    expect(GetRevisionHtmlWithCitations).not_to have_received(:new)
  end
end
