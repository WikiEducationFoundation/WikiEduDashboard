# frozen_string_literal: true

require 'rails_helper'

describe 'timeline editing', type: :feature, js: true do
  let(:start_date) { '2025-02-10'.to_date } # a Monday
  let(:submitted) { true }

  let(:course_with_timeline) do
    course = create(:course,
                    start: start_date,
                    end: start_date + 2.months,
                    timeline_start: start_date,
                    timeline_end: start_date + 2.months,
                    weekdays: '0101010',
                    submitted:)
    week = create(:week, course:)
    create(:block, week:,
                   id: 1,
                   kind: Block::KINDS['assignment'],
                   title: 'Block Title',
                   training_module_ids: [1],
                   order: 0,
                   points: 50)
    create(:block, week:,
                   id: 2,
                   kind: Block::KINDS['in_class'],
                   title: 'Another Title',
                   training_module_ids: [2],
                   order: 1)
    create(:block, week:,
                   id: 3,
                   kind: Block::KINDS['milestone'],
                   title: 'Third Title',
                   training_module_ids: [3],
                   points: 7,
                   order: 2)
    return course
  end

  let(:unassigned_module_name) { 'Translating articles' }

  before do
    TrainingModule.load_all
    include type: :feature
    include Devise::TestHelpers
    page.current_window.resize_to(1920, 1080)

    login_as create(:admin)
    stub_oauth_edit
  end

  it 'lets users add a training to an assignment block' do
    visit "/courses/#{course_with_timeline.slug}/timeline"

    # Interact with training modules within a block
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      find('.block__edit-block', match: :first).click
    end
    sleep 1
    within(".week-1 .block-kind-#{Block::KINDS['assignment']}") do
      within '.block__training-modules' do
        find('input').send_keys(unassigned_module_name, :enter)
      end
    end

    within('.block__block-actions') { click_button 'Save' }

    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      expect(page).to have_content unassigned_module_name
    end
    sleep 1
  end

  it 'lets users delete a week' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(page).not_to have_content 'Add Assignment'
    accept_confirm do
      find('button.week__delete-week').click
    end
    expect(page).to have_content 'Add Assignment'
    sleep 1
  end

  it 'lets users rename and reset week titles' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(page).not_to have_content 'Intro and Icebreaker'
    expect(page).to have_content 'Week 1'
    # Add new title
    click_button 'Edit Week Titles'
    find('input.week-title-input').native.clear
    find('input.week-title-input').set 'Intro and Icebreaker'
    # Save new title
    click_button 'Save All'
    expect(page).to have_content 'Intro and Icebreaker'
    expect(page).not_to have_content 'Week 1'
    # Reset to default titles
    click_button 'Edit Week Titles'
    accept_confirm { click_button 'Reset to Default' }

    expect(page).not_to have_content 'Intro and Icebreaker'
    expect(page).to have_content 'Week 1'
    sleep 1
  end

  it 'lets users delete a block' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(page).to have_content 'Block Title'
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      find('.block__edit-block', match: :first).click
      click_button 'Delete Block'
    end
    click_button 'OK'

    expect(page).not_to have_content 'Block Title'
    sleep 1
  end

  it 'handles cases of "save all" after blocks have been deleted' do
    # pending 'This sometimes fails for unknown reasons.'

    visit "/courses/#{course_with_timeline.slug}/timeline"

    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
    end

    # Open edit mode for the third block
    milestone_block = find(".week-1 .block-kind-#{Block::KINDS['milestone']}")
    scroll_to milestone_block
    sleep 0.5
    milestone_block.hover

    within ".week-1 .block-kind-#{Block::KINDS['milestone']}" do
      find('.block__edit-block', match: :first).click
    end

    # Open edit mode for the second block and delete it
    find(".week-1 .block-kind-#{Block::KINDS['in_class']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['in_class']}" do
      find('.block__edit-block', match: :first).click
      click_button 'Delete Block'
    end
    click_button 'OK'
    sleep 1

    # click Save All
    click_button 'Save All'
    expect(page).to have_content 'Block Title'
    expect(page).to have_content 'Third Title'
    expect(page).not_to have_content 'Another Title'
    sleep 1

    # pass_pending_spec
  end

  it 'lets users add a block' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(course_with_timeline.blocks.count).to eq(3)
    find('button.week__add-block').click
    sleep 0.5
    click_button 'Save'
    sleep 1
    expect(course_with_timeline.blocks.count).to eq(4)
  end

  it 'restores original content for a block upon cancelling edit mode' do
    visit "/courses/#{course_with_timeline.slug}/timeline"

    expect(page).to have_content 'Block Title'

    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
    end

    # Change the content
    find('input.title').native.clear
    find('input.title').set 'My New Title'
    expect(page).not_to have_content 'Block Title'

    # Cancel the change
    find('span', text: 'Cancel').click
    expect(page).to have_content 'Block Title'
  end

  it 'restores content for all blocks with "Discard All Changes"' do
    visit "/courses/#{course_with_timeline.slug}/timeline"

    # Change the first block
    assignment_block = find(".week-1 .block-kind-#{Block::KINDS['assignment']}")
    scroll_to assignment_block
    assignment_block.hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      find('.block__edit-block', match: :first).click
      find('input.title').native.clear
      find('input.title').set 'My New Title'
    end

    # Change the third block
    milestone_block = find(".week-1 .block-kind-#{Block::KINDS['milestone']}")
    scroll_to milestone_block
    milestone_block.hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['milestone']}" do
      find('.block__edit-block', match: :first).click
      find('input.title').native.clear
      find('input.title').set 'My Other New Title'
    end

    expect(page).not_to have_content 'Block Title'
    expect(page).not_to have_content 'Third Title'

    # Reset the changes
    click_button 'Discard All Changes'
    expect(page).not_to have_content 'My New Title'
    expect(page).not_to have_content 'My Other New Title'
    expect(page).to have_content 'Block Title'
    expect(page).to have_content 'Third Title'
  end

  context 'when the course is not submitted' do
    let(:submitted) { false }

    it 'lets users delete the whole timeline' do
      visit "/courses/#{course_with_timeline.slug}/timeline"
      accept_confirm { click_button 'Delete Timeline' }
      expect(page).to have_content 'Add Assignment'
    end
  end
end
