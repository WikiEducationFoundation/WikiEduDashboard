# frozen_string_literal: true

require 'rails_helper'

describe 'Resources tab', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:course) { create(:basic_course, flags: { timeline_enabled: }) }
  let(:week) { create(:week, course:) }

  before do
    login_as(admin)
    stub_oauth_edit
  end

  after { logout }

  context 'when the timeline is disabled and there are no resources blocks' do
    let(:timeline_enabled) { false }

    it 'shows neither the Timeline nor the Resources tab' do
      create(:block, week:, kind: Block::KINDS['in_class'], title: 'In class activity')
      visit "/courses/#{course.slug}/home"
      expect(page).to have_css('#overview-link')
      expect(page).to have_no_css('#timeline-link')
      expect(page).to have_no_css('#resources-link')
    end
  end

  context 'when the timeline is disabled but has a resources block' do
    let(:timeline_enabled) { false }

    it 'shows the Resources tab without the Timeline tab' do
      create(:block, week:, kind: Block::KINDS['resources'], title: 'Extra reading')
      visit "/courses/#{course.slug}/home"
      expect(page).to have_css('#resources-link')
      expect(page).to have_no_css('#timeline-link')
    end

    it 'renders the resources block on the Resources tab' do
      create(:block, week:, kind: Block::KINDS['resources'], title: 'Extra reading')
      visit "/courses/#{course.slug}/home"
      find('#resources-link a').click
      expect(page).to have_content 'Extra reading'
    end
  end

  context 'when the timeline is enabled' do
    let(:timeline_enabled) { true }

    it 'shows the Resources tab even without any resources blocks' do
      create(:block, week:, kind: Block::KINDS['in_class'], title: 'In class activity')
      visit "/courses/#{course.slug}/home"
      expect(page).to have_css('#timeline-link')
      expect(page).to have_css('#resources-link')
    end
  end
end
