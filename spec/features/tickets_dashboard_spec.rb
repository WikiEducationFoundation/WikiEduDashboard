# frozen_string_literal: true

require 'rails_helper'

describe 'ticket dashboard', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:course2) { create(:course, slug: 'course/2') }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }
  let(:user) { create(:user, username: 'arogers', email: 'aron@packers.nfl.org') }
  let(:user2) { create(:user, username: 'pmahomes', email: 'pat@chiefs.nfl.org') }
  let(:user3) { create(:user, username: 'orion', email: 'progo@nasa.org') }

  let(:create_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'I do not test content',
      owner_id: admin.id,
      sender_id: user.id,
      project_id: course.id,
      details: { subject: 'A first subject' }
    )
  end

  let(:create_another_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'I still do not test content',
      owner_id: admin.id,
      sender_id: user2.id,
      project_id: course2.id,
      details: { subject: 'A second subject' }
    )
  end

  let(:create_a_third_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'I circle around the moon waiting to splash',
      owner_id: admin.id,
      sender_id: user3.id,
      project_id: course2.id,
      details: { subject: 'Do no miss my return' }
    )
  end

  let(:select_from_selectbox) do
    lambda do |txt|
      find('#search_type_selector').click
      within '#search_type_selector' do
        selector = 'div[id^="react-select-search-type-option"]'
        find(selector, text: txt).click
      end
    end
  end

  before do
    login_as admin
    visit '/tickets/dashboard'
  end

  it 'displays a select input to chose search mode' do
    expect(page).to have_selector '#search_type_selector'
  end

  it 'displays a search bar' do
    expect(page).to have_field 'tickets_search'
  end

  it 'searchs for a token' do
    select_from_selectbox.call('Search by email or user name')
    fill_in 'tickets_search', with: 'no one is here'
    find('input[name="tickets_search"]').send_keys(:enter)

    expect(page).to have_content 'No tickets'
  end

  context 'When DB is populated' do
    before do
      create_ticket
      create_another_ticket
      create_a_third_ticket
      create(:courses_user, course:, user:,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course: course2, user: user2,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      visit '/tickets/dashboard'
    end

    it 'finds one match with email' do
      select_from_selectbox.call('Search by email or user name')
      fill_in 'tickets_search', with: 'aron@packers.nfl.org'
      find('input[name="tickets_search"]').send_keys(:enter)

      expect(page).to have_content 'arogers'
    end

    it 'finds one match with username' do
      select_from_selectbox.call('Search by email or user name')

      fill_in 'tickets_search', with: 'pmahomes'
      find('input[name="tickets_search"]').send_keys(:enter)

      expect(page).to have_content 'pmahomes'
    end

    it 'finds two matches in subject' do
      select_from_selectbox.call('Search in subject')

      fill_in 'tickets_search', with: 'subject'
      find('input[name="tickets_search"]').send_keys(:enter)

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 2
    end

    it 'finds one match in content' do
      select_from_selectbox.call('Search in content')

      fill_in 'tickets_search', with: 'splash'
      find('input[name="tickets_search"]').send_keys(:enter)

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end
  end
end
