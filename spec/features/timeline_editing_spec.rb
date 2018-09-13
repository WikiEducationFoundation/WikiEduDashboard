# frozen_string_literal: true

require 'rails_helper'

def create_course
  start_date = '2025-02-10'.to_date # a Monday
  create(:course,
         id: 10001,
         start: start_date,
         end: start_date + 2.months,
         timeline_start: start_date,
         timeline_end: start_date + 2.months,
         weekdays: '0101010',
         submitted: true)
  create(:week,
         id: 1,
         course_id: 10001)
  create(:block,
         id: 1,
         week_id: 1,
         kind: Block::KINDS['assignment'],
         title: 'Block Title',
         order: 0,
         points: 50)
  create(:block,
         id: 2,
         week_id: 1,
         kind: Block::KINDS['in_class'],
         title: 'Another Title',
         order: 1)
  create(:block,
         id: 3,
         week_id: 1,
         kind: Block::KINDS['milestone'],
         title: 'Third Title',
         points: 7,
         order: 2)
end

describe 'timeline editing', type: :feature, js: true do
  let(:unassigned_module_name) { 'Peer review' }

  before do
    include type: :feature
    include Devise::TestHelpers
    page.current_window.resize_to(1920, 1080)

    create_course
    login_as create(:admin)
    stub_oauth_edit
  end

  it 'lets users add a training to an assignment block' do
    visit "/courses/#{Course.last.slug}/timeline"

    # Interact with training modules within a block
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      find('.block__edit-block', match: :first).click
    end
    sleep 1
    within(".week-1 .block-kind-#{Block::KINDS['assignment']}") do
      find('div.Select--multi').send_keys(unassigned_module_name, :enter)
    end

    within('.block__block-actions') { click_button 'Save' }

    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      expect(page).to have_content unassigned_module_name
    end
    sleep 1
  end

  it 'lets users delete a week' do
    visit "/courses/#{Course.first.slug}/timeline"
    expect(page).not_to have_content 'Add Assignment'
    accept_confirm do
      find('button.week__delete-week').click
    end
    expect(page).to have_content 'Add Assignment'
    sleep 1
  end

  it 'lets users delete a block' do
    visit "/courses/#{Course.first.slug}/timeline"
    expect(page).to have_content 'Block Title'
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      find('.block__edit-block', match: :first).click
      accept_confirm do
        click_button 'Delete Block'
      end
    end

    expect(page).not_to have_content 'Block Title'
    sleep 1
  end

  it 'handles cases of "save all" after blocks have been deleted' do
    visit "/courses/#{Course.last.slug}/timeline"

    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
    end

    # Open edit mode for the third block
    find(".week-1 .block-kind-#{Block::KINDS['milestone']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['milestone']}" do
      find('.block__edit-block', match: :first).click
    end

    # Open edit mode for the second block and delete it
    find(".week-1 .block-kind-#{Block::KINDS['in_class']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['in_class']}" do
      find('.block__edit-block', match: :first).click
      accept_confirm do
        click_button 'Delete Block'
      end
    end
    sleep 1

    # click Save All
    click_button 'Save All'
    expect(page).to have_content 'Block Title'
    expect(page).to have_content 'Third Title'
    expect(page).not_to have_content 'Another Title'
    sleep 1
  end

  it 'lets users remove grading from a block' do
    visit "/courses/#{Course.last.slug}/timeline"
    expect(Block.find(1).points).to eq(50)
    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
    end
    within 'p.graded' do
      find('input').click
    end
    click_button 'Save'
    sleep 1
    expect(Block.find(1).points).to eq(nil)
  end

  it 'lets users add a block' do
    visit "/courses/#{Course.first.slug}/timeline"
    expect(Block.count).to eq(3)
    find('button.week__add-block').click
    click_button 'Save'
    sleep 1
    expect(Block.count).to eq(4)
  end

  it 'restores original content for a block upon cancelling edit mode' do
    visit "/courses/#{Course.first.slug}/timeline"

    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
    end

    # Change the content
    find('input.title').set 'My New Title'
    expect(page).not_to have_content 'Block Title'
    expect(page).to have_content 'My New Title'

    # Cancel the change
    find('span', text: 'Cancel').click
    expect(page).to have_content 'Block Title'
    expect(page).not_to have_content 'My New Title'
  end

  it 'restores content for all blocks with "Discard All Changes"' do
    visit "/courses/#{Course.first.slug}/timeline"

    # Change the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
      find('input.title').set 'My New Title'
    end

    # Change the third block
    find(".week-1 .block-kind-#{Block::KINDS['milestone']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['milestone']}" do
      find('.block__edit-block', match: :first).click
      find('input.title').set 'My Other New Title'
    end

    expect(page).to have_content 'My New Title'
    expect(page).to have_content 'My Other New Title'
    expect(page).not_to have_content 'Block Title'
    expect(page).not_to have_content 'Third Title'

    # Reset the changes
    click_button 'Discard All Changes'
    expect(page).not_to have_content 'My New Title'
    expect(page).not_to have_content 'My Other New Title'
    expect(page).to have_content 'Block Title'
    expect(page).to have_content 'Third Title'
  end
end
