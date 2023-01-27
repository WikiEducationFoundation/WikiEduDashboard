# frozen_string_literal: true

require 'rails_helper'

describe 'ticket dashboard', type: :feature, js: true do
  let(:course) do
    create(:course,
           slug: 'NASA_School/Fly_me_to_the_moon',
           title: 'Fly me to the moon')
  end
  let(:course2) { create(:course, slug: 'Pasteur_Institue/Intro_to_microbiology') }
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

    it 'finds one match by course slug' do
      select_from_selectbox.call('Search by course slug')

      fill_in 'tickets_search', with: 'NASA_School/Fly_me_to_the_moon'
      find('input[name="tickets_search"]').send_keys(:enter)

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end

    it 'finds no match with an unknown slug' do
      select_from_selectbox.call('Search by course slug')

      fill_in 'tickets_search', with: 'Unknown_School/school_is_closed'
      find('input[name="tickets_search"]').send_keys(:enter)

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 0
    end

    it 'displays tickets coming from course page', :aggregate_failures do
      stub_oauth_edit
      visit "/courses/#{course.slug}"
      find_link(I18n.t('courses.search_all_tickets_for_this_course')).click
      url = URI(current_url)
      param, slug = url.query.split('=')

      expect(url.path).to eq '/tickets/dashboard'
      expect(param).to eq 'search_by_course'
      expect(slug).to eq course.slug
      expect(find('input[name="tickets_search"]').value).to eq course.slug
      expect(find_link(course.title).visible?).to be true
    end

    it 'displays tickets coming from a ticket page', :aggregate_failures do
      stub_oauth_edit
      ticket = TicketDispenser::Ticket.first
      visit "/tickets/dashboard/#{ticket.id}"

      # bc opens in a new tab
      ticket_window = window_opened_by do
        find_link("Search all tickets for: #{ticket.project.title}").click
      end
      within_window ticket_window do
        url = URI(current_url)
        param, slug = url.query.split('=')
        expect(url.path).to eq '/tickets/dashboard'
        expect(param).to eq 'search_by_course'
        expect(slug).to eq course.slug
        expect(find('input[name="tickets_search"]').value).to eq course.slug
        expect(find_link(course.title).visible?).to be true
      end
    end
  end
end
