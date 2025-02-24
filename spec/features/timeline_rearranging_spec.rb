# frozen_string_literal: true

require 'rails_helper'

describe 'timeline editing', feature: true, js: true do
  let(:course) do
    create(:course, id: 10001, start: Date.new(2015, 1, 1),
                    end: Date.new(2015, 2, 1), submitted: true,
                    timeline_start: Date.new(2015, 1, 1), timeline_end: Date.new(2015, 2, 1),
                    weekdays: '0111110')
  end
  let(:user) { create(:user, permissions: User::Permissions::ADMIN) }
  let!(:c_user) { create(:courses_user, course_id: course.id, user_id: user.id) }

  let(:week) { create(:week, course_id: course.id, order: 1) }
  let(:week2) { create(:week, course_id: course.id, order: 2) }

  before do
    page.current_window.resize_to(1920, 1080)
    TrainingModule.load_all
    stub_oauth_edit

    login_as user, scope: :user, run_callbacks: false

    create(:block, week_id: week.id, kind: Block::KINDS['assignment'], order: 0, title: 'Block 1')
    create(:block, week_id: week.id, kind: Block::KINDS['in_class'], order: 1, title: 'Block 2')
    create(:block, week_id: week.id, kind: Block::KINDS['in_class'], order: 2, title: 'Block 3')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 0, title: 'Block 4')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 1, title: 'Block 5')
    create(:block, week_id: week2.id, kind: Block::KINDS['in_class'], order: 3, title: 'Block 6')
  end

  it 'disables reorder up/down buttons when it is the first or last block' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # Different Capybara drivers have slightly different behavior for disabled vs. not.
    truthy_values = [true, 'true']
    falsy_values = [nil, false, 'false']

    expect(falsy_values).to include(
      find('.week-1 .week__block-list > li:first-child button:first-of-type')['disabled']
    )
    expect(truthy_values).to include(
      find('.week-1 .week__block-list > li:first-child button:last-of-type')['disabled']
    )
    expect(truthy_values).to include(
      find('.week-2 .week__block-list > li:last-child button:first-of-type')['disabled']
    )
    expect(falsy_values).to include(
      find('.week-2 .week__block-list > li:last-child button:last-of-type')['disabled']
    )
  end

  it 'allows swapping places with a block' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'
    # move down
    omniclick find('.week-1 .week__block-list > li:nth-child(1) button:first-of-type')
    sleep 0.5
    # move down again
    omniclick find('.week-1 .week__block-list > li:nth-child(2) button:first-of-type')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(1)')).to have_content('Block 2')
    expect(find('.week-1 .week__block-list > li:nth-child(2)')).to have_content('Block 3')
    expect(find('.week-1 .week__block-list > li:nth-child(3)')).to have_content('Block 1')
    # move up
    omniclick find('.week-1 .week__block-list > li:nth-child(3) button:last-of-type')
    sleep 0.5
    # move up again
    omniclick find('.week-1 .week__block-list > li:nth-child(2) button:last-of-type')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(1)')).to have_content('Block 1')
    expect(find('.week-1 .week__block-list > li:nth-child(2)')).to have_content('Block 2')
    expect(find('.week-1 .week__block-list > li:nth-child(3)')).to have_content('Block 3')
  end

  it 'allows dragging and dropping blocks' do
    # pending 'Drag and drop does not work in Capybara after upgrading react-dnd'
    # https://github.com/react-dnd/react-dnd/issues/1195

    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    first_block = find('.week-1 .week__block-list > li:nth-child(1)')
    expect(first_block).to have_content 'Block 1'
    later_block = find('.week-2 .week__block-list > li:nth-child(1)')

    first_block.drag_to(later_block)
    sleep 0.5
    expect(find('.week-2 .week__block-list > li:nth-child(1)')).to have_content 'Block 1'

    # pass_pending_spec
  end

  it 'allows moving blocks between weeks' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # move up to week 1
    omniclick find('.week-2 .week__block-list > li:nth-child(1) button:last-of-type')
    sleep 0.5
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'

    # move back down to week 2
    omniclick find('.week-1 .week__block-list > li:nth-child(4) button:first-of-type')
    sleep 0.5
    expect(find('.week-2 .week__block-list > li:nth-child(1)')).to have_content 'Block 4'
  end

  it 'allows user to save and discard changes' do
    visit "/courses/#{Course.last.slug}/timeline"
    click_button 'Arrange Timeline'

    # move up to week 1
    omniclick find('.week-2 .week__block-list > li:nth-child(1) button:last-of-type')
    click_button 'Save All'
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'

    # move down to week 2 and discard Changes
    click_button 'Arrange Timeline'
    omniclick find('.week-1 .week__block-list > li:nth-child(4) button:first-of-type')
    click_button 'Discard All Changes'
    # still in week 1
    expect(find('.week-1 .week__block-list > li:nth-child(4)')).to have_content 'Block 4'
  end
end
