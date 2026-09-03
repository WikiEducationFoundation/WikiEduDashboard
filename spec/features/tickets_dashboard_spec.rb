# frozen_string_literal: true

require 'rails_helper'

describe 'ticket dashboard', type: :feature, js: true do
  let(:course) do
    create(:course,
           slug: 'NASA_School/Fly_me_to_the_moon',
           title: 'Fly me to the moon')
  end
  let(:course2) { create(:course, slug: 'abc_school/words') }
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

  let(:create_a_fourth_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'Goodbye',
      owner_id: admin.id,
      sender_id: user3.id,
      project_id: course2.id,
      details: { subject: 'I will not come back' }
    )
  end

  before do
    login_as admin
    visit '/tickets/dashboard'
    expect(page).to have_field 'tickets_search_email_or_username'
  end

  it 'displays all search bars' do
    expect(page).to have_field 'tickets_search_email_or_username'
    expect(page).to have_field 'tickets_search_subject'
    expect(page).to have_field 'tickets_search_content'
    expect(page).to have_field 'tickets_search_course'
  end

  it 'searches for a token' do
    fill_in 'tickets_search_content', with: 'no one is here'
    click_button 'search_tickets'

    expect(page).to have_content 'No tickets'
  end

  context 'When DB is populated' do
    before do
      create_ticket
      create_another_ticket
      create_a_third_ticket
      create_a_fourth_ticket
      create(:courses_user, course:, user:,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course: course2, user: user2,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      visit '/tickets/dashboard'
    end

    it 'clears search when button is pressed after a search occurs' do
      fill_in 'tickets_search_email_or_username', with: 'aron@packers.nfl.org'
      click_button 'search_tickets'
      expect(page).to have_no_content 'pmahomes'

      click_button 'clear_search'
      expect(page).to have_content 'pmahomes'
    end

    it 'finds one match with email' do
      fill_in 'tickets_search_email_or_username', with: 'aron@packers.nfl.org'
      click_button 'search_tickets'

      expect(page).to have_content 'arogers'
    end

    it 'finds one match with username' do
      fill_in 'tickets_search_email_or_username', with: 'pmahomes'
      click_button 'search_tickets'

      expect(page).to have_content 'pmahomes'
    end

    it 'finds two matches in subject' do
      fill_in 'tickets_search_subject', with: 'subject'
      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 2
      expect(page).to be_axe_clean
    end

    it 'finds one match in content' do
      fill_in 'tickets_search_content', with: 'splash'
      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end

    it 'finds one match by course slug' do
      fill_in 'tickets_search_course', with: 'NASA_School/Fly_me_to_the_moon'
      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end

    it 'finds two matches by course slug and content' do
      fill_in 'tickets_search_course', with: 'abc_school/words'
      fill_in 'tickets_search_content', with: 'I'

      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 2
    end

    it 'finds one match by course slug and content and email' do
      fill_in 'tickets_search_course', with: 'abc_school/words'
      fill_in 'tickets_search_content', with: 'I'
      fill_in 'tickets_search_email_or_username', with: 'progo@nasa.org'

      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end

    it 'finds one match by course slug and content and email and subject' do
      fill_in 'tickets_search_course', with: 'abc_school/words'
      fill_in 'tickets_search_content', with: 'Goodbye'
      fill_in 'tickets_search_email_or_username', with: 'progo@nasa.org'
      fill_in 'tickets_search_subject', with: 'I will not come back'

      click_button 'search_tickets'

      nb_of_lines = within 'tbody' do
        all('tr[class^="table-row"]')
      end.count

      expect(nb_of_lines).to eq 1
    end

    it 'finds no match with an unknown slug' do
      fill_in 'tickets_search_course', with: 'Unknown_School/school_is_closed'
      click_button 'search_tickets'

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
      expect(find('input[name="tickets_search_course"]').value).to eq course.slug
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

      # Trying to work around intermittent failures on CI.
      # Maybe the "no such execution context" error is
      # because the new tab hasn't fully initialized
      # by the time the block below tries to get the URL.
      sleep 1

      within_window ticket_window do
        url = URI(current_url)
        param, slug = url.query.split('=')
        expect(url.path).to eq '/tickets/dashboard'
        expect(param).to eq 'search_by_course'
        expect(slug).to eq course.slug
        expect(find('input[name="tickets_search_course"]').value).to eq course.slug
        expect(find_link(course.title).visible?).to be true
      end
    end

    it 'lists tickets after returning from a ticket page that was loaded directly' do
      ticket = TicketDispenser::Ticket.first
      # A full page load, so the ticket page is the first thing the React
      # store sees, as when following the link in a notification email.
      visit "/tickets/dashboard/#{ticket.id}"
      expect(page).to have_content 'Send a Reply'
      # Opening the ticket marks its messages read. That update used to sneak
      # the ticket into the (never fetched) index list, so the dashboard
      # skipped loading and spun forever.
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.1 until ticket.messages.reload.all?(&:read)
      end

      click_link '← Ticketing Dashboard'
      expect(page).to have_content 'A first subject'
      expect(page).to have_content 'A second subject'
    end

    it 'shows a reply-and-resolve in the ticket list without a refresh' do
      within('tr', text: 'A first subject') { click_link 'Show' }
      within('form.tickets-reply') do
        find('.wysiwyg-editor__content').click
        find('.wysiwyg-editor__content').send_keys('All set now.')
      end
      click_button 'Send Reply and Resolve Ticket'
      expect(page).to have_content 'Ticket is currently Resolved'

      click_link '← Ticketing Dashboard'
      # The default filter shows open tickets only, so the resolved one drops out.
      expect(page).to have_content 'A second subject'
      expect(page).to have_no_content 'A first subject'
    end
  end
end
