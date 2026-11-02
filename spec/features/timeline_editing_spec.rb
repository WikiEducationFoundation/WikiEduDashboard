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
    page.current_window.resize_to(1920, 1080)

    login_as create(:admin)
    stub_oauth_edit
  end

  it 'lets users add a training to an assignment block' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(page).to have_content 'Block Title'
    expect(page).to be_axe_clean

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

  it 'lets users add the fact verification exercise to an assignment block' do
    visit "/courses/#{course_with_timeline.slug}/timeline"
    expect(page).to have_content 'Block Title'

    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      find('.block__edit-block', match: :first).click
    end
    sleep 1
    within(".week-1 .block-kind-#{Block::KINDS['assignment']}") do
      within '.block__training-modules' do
        find('input').send_keys('Fact verification', :enter)
      end
    end

    within('.block__block-actions') { click_button 'Save' }

    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      expect(page).to have_content 'Fact verification'
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
    expect(page).not_to have_content 'Another Title'

    # click Save All
    click_button 'Save All'
    expect(page).to have_content 'Block Title'
    expect(page).to have_content 'Third Title'
    expect(page).not_to have_content 'Another Title'
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

  describe 'block due dates' do
    let(:in_class_block) { course_with_timeline.blocks.find_by(kind: Block::KINDS['in_class']) }
    let(:in_class_selector) { ".week-1 .block-kind-#{Block::KINDS['in_class']}" }

    def edit_in_class_block
      visit "/courses/#{course_with_timeline.slug}/timeline"
      find(in_class_selector).hover
      sleep 0.5
      within(in_class_selector) { find('.block__edit-block', match: :first).click }
    end

    it 'shows the default due date for a block with modules' do
      edit_in_class_block
      within(in_class_selector) do
        # Timeline starts Mon 2025-02-10; week 1 defaults to that Saturday.
        expect(page).to have_content 'Default (Sat, Feb 15, 2025)'
        expect(page).not_to have_content 'No due date'
      end
    end

    it 'sets a due date on a non-assignment block' do
      edit_in_class_block
      within(in_class_selector) do
        choose 'Set a date'
        within('.block__block-due-date') { find('input.due_date').set('2025-02-13') }
        find('legend', text: 'Due date').click # blur the date field
        click_button 'Save'
      end
      expect(page).to have_css("#{in_class_selector} .block__read__due-date")
      expect(in_class_block.reload.due_date).to eq('2025-02-13'.to_date)
    end

    it 'removes a due date left on a block that is no longer an assignment' do
      in_class_block.update(due_date: '2025-02-13'.to_date)
      edit_in_class_block
      within(in_class_selector) do
        expect(find_field('Set a date')).to be_checked
        choose 'Default'
        click_button 'Save'
      end
      expect(page).not_to have_css("#{in_class_selector} .block__read__due-date")
      expect(in_class_block.reload.due_date).to be_nil
    end
  end
end
