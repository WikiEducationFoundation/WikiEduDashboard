require 'rails_helper'

def create_course
  create(:course,
         id: 10001,
         start: Date.today - 1.month,
         end: Date.today + 1.month,
         timeline_start: Date.today - 1.month,
         timeline_end: Date.today + 1.month,
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
         gradeable_id: 1)
  create(:gradeable,
         id: 1,
         gradeable_item_id: 1,
         gradeable_item_type: 'block')
  create(:block,
         id: 2,
         week_id: 1,
         kind: Block::KINDS['in_class'],
         title: 'Another Title',
         order: 1)
end

describe 'timeline editing', type: :feature, js: true do
  let(:unassigned_module_name) { 'Editing Basics' }

  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
    page.current_window.resize_to(1920, 1080)

    create(:cohort)
    create_course
    login_as create(:admin)
    stub_oauth_edit
  end

  it 'lets users delete a week' do
    visit "/courses/#{Course.first.slug}/timeline"
    expect(page).not_to have_content 'Add Assignment'
    accept_confirm do
      find('span.week__delete-week').click
    end
    expect(page).to have_content 'Add Assignment'
  end

  it 'lets users delete a block' do
    visit "/courses/#{Course.first.slug}/timeline"
    expect(page).to have_content 'Block Title'
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      first('.block__edit-block').click
      accept_confirm do
        click_button 'Delete Block'
      end
    end

    expect(page).not_to have_content 'Block Title'
  end

  it 'lets users add a training to an assignment block' do
    visit "/courses/#{Course.last.slug}/timeline"

    # Interact with training modules within a block
    find('.week-1').hover
    sleep 0.5
    within('.week-1') do
      first('.block__edit-block').click
    end
    sleep 1
    within(".week-1 .block-kind-#{Block::KINDS['assignment']}") do
      find('.Select-control input').set(unassigned_module_name[0..5])
      find('.Select-menu-outer .Select-option', text: unassigned_module_name).click
    end
    within('.block__block-actions') { click_button 'Save' }

    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      expect(page).to have_content unassigned_module_name
    end
  end

  it 'handles cases of "save all" after blocks have been deleted' do
    visit "/courses/#{Course.last.slug}/timeline"

    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      first('.block__edit-block').click
    end

    # Open edit mode for the second block and delete it
    find(".week-1 .block-kind-#{Block::KINDS['in_class']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['in_class']}" do
      first('.block__edit-block').click
      accept_confirm do
        click_button 'Delete Block'
      end
    end

    # click Save All
    click_button 'Save All'
    expect(page).to have_content 'Block Title'
    expect(page).not_to have_content 'Another Title'
  end

  it 'lets users remove grading from a block' do
    visit "/courses/#{Course.last.slug}/timeline"
    # Open edit mode for the first block
    find(".week-1 .block-kind-#{Block::KINDS['assignment']}").hover
    sleep 0.5
    within ".week-1 .block-kind-#{Block::KINDS['assignment']}" do
      first('.block__edit-block').click
    end
    within 'p.graded' do
      find('input').click
    end
    click_button 'Save'
    sleep 1
    expect(Gradeable.all).to be_empty
  end
end
