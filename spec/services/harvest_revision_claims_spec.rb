# frozen_string_literal: true

require 'rails_helper'

describe HarvestRevisionClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, subject: 'Sociology') }

  # One cited sentence with a linkable web source, one with an offline book.
  let(:html) do
    <<~HTML
      <p>The site opened in 1990.<sup class="reference"><a href="#cite_note-web-1">[1]</a></sup>
      A book says otherwise.<sup class="reference"><a href="#cite_note-book-2">[2]</a></sup></p>
      <ol class="references">
        <li id="cite_note-web-1"><span class="reference-text"><cite class="citation web">
          <a class="external text" href="https://example.com/history">"History"</a>.</cite></span></li>
        <li id="cite_note-book-2"><span class="reference-text"><cite class="citation book">
          Smith, J. (2001). <i>A Book</i>.</cite></span></li>
      </ol>
    HTML
  end

  def harvest
    described_class.new(html:, wiki:, subject: 'Sociology', source_course: course,
                        article_title: 'Example', mw_rev_id: 12_345)
  end

  it 'stores a pool entry for every cited claim, offline sources included' do
    expect { harvest }.to change(VerificationClaim, :count).by(2)
  end

  it 'flags the source bar without filtering on it' do
    harvest
    web = VerificationClaim.find_by(ref_id: 'cite_note-web-1')
    book = VerificationClaim.find_by(ref_id: 'cite_note-book-2')
    expect([web.offline_source, web.source_url])
      .to eq([false, 'https://example.com/history'])
    expect([book.offline_source, book.source_url]).to eq([true, nil])
  end

  it 'records provenance from the source revision and course' do
    harvest
    claim = VerificationClaim.find_by(ref_id: 'cite_note-web-1')
    expect([claim.mw_rev_id, claim.article_title, claim.source_course_id])
      .to eq([12_345, 'Example', course.id])
  end

  it 'does not duplicate pool entries when the same revision is re-harvested' do
    harvest
    expect { harvest }.not_to change(VerificationClaim, :count)
  end

  describe 'student-added provenance' do
    let(:courses_user) { create(:courses_user, course:, user: create(:user)) }

    it 'records the courses_user when given one (eg harvesting a student diff)' do
      described_class.new(html:, wiki:, source_course: course, courses_user:)
      expect(VerificationClaim.pluck(:courses_users_id).uniq).to eq([courses_user.id])
    end

    it 'leaves courses_users_id null when no student is given' do
      harvest
      expect(VerificationClaim.pluck(:courses_users_id).uniq).to eq([nil])
    end
  end
end
