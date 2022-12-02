# frozen_string_literal: true

require 'rails_helper'

describe 'ticket dashboard', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:course2) { create(:course, slug: 'course/2') }
  let(:admin) { create(:admin, email: 'spec@wikiedu.org') }
  let(:user) { create(:user, username: 'Aaron Rodgers', email: 'student@harvard.edu.org') }
  let(:user2) { create(:user, username: 'Customer service', email: 'support@rodgers.ca') }

  let(:create_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'I do not test content',
      owner_id: admin.id,
      sender_id: user.id,
      project_id: course.id
    )
  end

  let(:create_another_ticket) do
    TicketDispenser::Dispenser.call(
      content: 'I still do not test content',
      owner_id: admin.id,
      sender_id: user2.id,
      project_id: course2.id
    )
  end

  before do
    login_as admin
  end

  it 'displays a button to switch modes' do
    visit '/tickets/dashboard'
    expect(page).to have_button 'toggle-mode-button'
  end

  it 'displays a search bar' do
    visit '/tickets/dashboard'
    click_button 'toggle-mode-button'

    expect(page).to have_field 'tickets-search'
  end

  it 'searchs for a token' do
    visit '/tickets/dashboard'
    click_button 'toggle-mode-button'

    fill_in 'tickets-search', with: 'Jimmy'
    find('input[name="tickets-search"]').send_keys(:enter)

    expect(page).to have_content 'No tickets'
  end

  context 'When DB is populated' do
    before do
      create_ticket
      create_another_ticket
      create(:courses_user, course:, user:,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course: course2, user: user2,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      visit '/tickets/dashboard'
      click_button 'toggle-mode-button'
    end

    it 'finds one match in username' do
      fill_in 'tickets-search', with: 'ron'
      find('input[name="tickets-search"]').send_keys(:enter)

      expect(page).to have_content 'Aaron Rodgers'
    end

    it 'finds 2 tickets by matching email and surname' do
      fill_in 'tickets-search', with: 'Rodger'
      find('input[name="tickets-search"]').send_keys(:enter)

      expect(page).to have_content('Customer service').and have_content('Aaron Rodgers')
    end
  end
end
