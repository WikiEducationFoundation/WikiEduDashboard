# frozen_string_literal: true

require 'rails_helper'

describe 'course update statistics', type: :feature, js: true do
  let(:course) { create(:course, flags: update_logs) }
  let(:update_logs) do
    {
      'update_logs' => {
        1 => {
          'start_time' => 10.minutes.ago,
          'end_time' => 5.minutes.ago,
          'error_count' => 0
        }
      },
     'average_update_delay' => 1.hour.to_s
    }
  end

  before { allow(Features).to receive(:wiki_ed?).and_return(false) }

  it 'shows info in a modal' do
    visit "/courses/#{course.slug}"
    click_link 'See more'
    expect(page).to have_content('The last update ran successfully')
  end
end
