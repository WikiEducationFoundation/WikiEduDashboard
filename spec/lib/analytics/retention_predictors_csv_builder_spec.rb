# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/retention_predictors_csv_builder"

describe RetentionPredictorsCsvBuilder do
  let(:course) do
    create(:course, start: Time.zone.local(2026, 1, 1),
                    end: Time.zone.local(2026, 1, 31, 23, 59, 59))
  end
  let(:wiki1) { Wiki.find_or_create_by(language: 'en', project: 'wikipedia') }
  let(:wiki2) { Wiki.find_or_create_by(language: 'es', project: 'wikipedia') }
  let(:user1) { create(:user, username: 'user1') }
  let(:user2) { create(:user, username: 'user2') }

  before do
    # The Wiki model validates against the live API on create; skip that here.
    allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists)
    course.wikis = [wiki1, wiki2]
    create(:courses_user, course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  # Builds a stub MediaWiki API response object for a list of edit Times.
  def response_for(times, continue: nil)
    contribs = times.map { |t| { 'timestamp' => t.utc.strftime('%Y-%m-%dT%H:%M:%SZ') } }
    instance_double(MediawikiApi::Response).tap do |response|
      allow(response).to receive(:data).and_return('usercontribs' => contribs)
      allow(response).to receive(:[]).with('continue').and_return(continue)
    end
  end

  # Stubs WikiApi.new(wiki) so that usercontribs queries return the given
  # per-username timestamps. `contribs_by_user` maps username => [Time, ...].
  def stub_wiki(wiki, contribs_by_user)
    api = instance_double(WikiApi)
    allow(WikiApi).to receive(:new).with(wiki).and_return(api)
    allow(api).to receive(:query) do |params|
      response_for(contribs_by_user.fetch(params[:ucuser], []))
    end
  end

  let(:subject) { described_class.new(course).generate_csv }
  let(:rows) { CSV.parse(subject, headers: true) }
  let(:user1_row) { rows.find { |r| r['username'] == 'user1' } }

  describe '#generate_csv' do
    before do
      # user1 on en.wikipedia: two clusters during the course, one after.
      stub_wiki(wiki1, 'user1' => [
                  Time.zone.local(2026, 1, 5, 10, 0),   # cluster A (during)
                  Time.zone.local(2026, 1, 5, 10, 30),  # +30 min -> same session
                  Time.zone.local(2026, 1, 10, 14, 0),  # cluster B (during), days later
                  Time.zone.local(2026, 2, 15, 9, 0)    # after course end
                ])
      # user1 on es.wikipedia: one edit during (45 min after the 10:00 wiki1 edit)
      # and one after (30 min after the wiki1 post-course edit).
      stub_wiki(wiki2, 'user1' => [
                  Time.zone.local(2026, 1, 5, 10, 45),
                  Time.zone.local(2026, 2, 15, 9, 30)
                ])
    end

    it 'counts distinct per-wiki sessions using the one-hour gap rule' do
      expect(user1_row['en.wikipedia.org sessions (during course)']).to eq('2')
      expect(user1_row['es.wikipedia.org sessions (during course)']).to eq('1')
    end

    it 'splits sessions before and after the course end date' do
      expect(user1_row['en.wikipedia.org sessions (after course)']).to eq('1')
      expect(user1_row['es.wikipedia.org sessions (after course)']).to eq('1')
    end

    it 'merges timestamps across wikis for the combined session counts' do
      # During: 10:00, 10:30, 10:45 collapse to one session; 01-10 is a second.
      expect(user1_row['all wikis sessions (during course)']).to eq('2')
      # After: 09:00 and 09:30 collapse to one session.
      expect(user1_row['all wikis sessions (after course)']).to eq('1')
    end

    it 'reports zeros for a student with no edits' do
      user2_row = rows.find { |r| r['username'] == 'user2' }
      expect(user2_row.fields[1..]).to all(eq('0'))
    end
  end

  describe 'pagination' do
    before do
      first = response_for([Time.zone.local(2026, 1, 5, 10, 0)], continue: { 'uccontinue' => 'x' })
      second = response_for([Time.zone.local(2026, 1, 20, 10, 0)])
      api1 = instance_double(WikiApi)
      allow(WikiApi).to receive(:new).with(wiki1).and_return(api1)
      allow(api1).to receive(:query).and_return(first, second)
      stub_wiki(wiki2, {})
    end

    it 'follows the continue token to fetch all pages of contributions' do
      # The two pages are days apart, so both must be fetched to count 2 sessions.
      expect(user1_row['en.wikipedia.org sessions (during course)']).to eq('2')
    end
  end
end
