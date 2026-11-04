# frozen_string_literal: true

require 'rails_helper'

describe 'application form settings', type: :feature, js: true do
  let(:course) { create(:fellows_cohort, slug: 'Wiki_Education/Elections_workshop_(2027)') }
  let(:base) { create(:question_group, name: 'Base questions') }
  let(:theme) { create(:question_group, name: 'Theme questions') }
  let!(:spare) { create(:question_group, name: 'Spare questions') }

  before do
    CourseApplicationForm.create!(course:, question_group_ids: [base.id, theme.id])
    login_as create(:admin)
    visit "/courses/#{course.slug}/application_form"
  end

  def listed_groups
    all('[data-question-group-list] .course-application-form__group-name').map(&:text)
  end

  # Drags `source` over the top quarter of `target`, as a person dropping it
  # above that row would. (Html5DndHelper drops on the exact middle, where
  # rounding decides above or below.)
  def drag_above(source, target)
    page.execute_script(<<~JS, source.native, target.native)
      const [source, target] = arguments;
      const transfer = new DataTransfer();
      const rect = target.getBoundingClientRect();
      const fire = (element, type) => element.dispatchEvent(new DragEvent(type, {
        dataTransfer: transfer, bubbles: true, cancelable: true,
        clientX: rect.left + rect.width / 2, clientY: rect.top + rect.height / 4
      }));
      fire(source, 'dragstart');
      fire(target, 'dragover');
      fire(target, 'drop');
      fire(source, 'dragend');
    JS
  end

  def saved_groups
    course.reload.course_application_form.added_question_groups.map(&:name)
  end

  it 'lists the built-in questions first, with nothing to move or remove' do
    built_in = find('.course-application-form__group--built-in')
    expect(built_in).to have_content(CourseApplicationDefaultQuestions.group.name)
    expect(built_in).to have_no_button
  end

  it 'reorders by drag-and-drop' do
    theme_row = find('[data-question-group-id]', text: 'Theme questions')
    base_row = find('[data-question-group-id]', text: 'Base questions')
    drag_above(theme_row, base_row)
    expect(listed_groups).to eq(['Theme questions', 'Base questions'])
    click_button 'Save'
    expect(page).to have_content('Saved')
    expect(saved_groups).to eq(['Theme questions', 'Base questions'])
  end

  it 'reorders with the Move buttons' do
    within('[data-question-group-id]', text: 'Theme questions') { click_button 'Move up' }
    expect(listed_groups).to eq(['Theme questions', 'Base questions'])
    click_button 'Save'
    expect(page).to have_content('Saved')
    expect(saved_groups).to eq(['Theme questions', 'Base questions'])
  end

  it 'removes a group and offers it to add again' do
    within('[data-question-group-id]', text: 'Base questions') { click_button 'Remove' }
    expect(listed_groups).to eq(['Theme questions'])
    find('.course-application-form__add .ts-control').click
    expect(page).to have_css('.ts-dropdown .option', text: 'Base questions')
    click_button 'Save'
    expect(page).to have_content('Saved')
    expect(saved_groups).to eq(['Theme questions'])
  end

  it 'adds a picked group to the end' do
    find('.course-application-form__add .ts-control').click
    find('.ts-dropdown .option', text: 'Spare questions').click
    click_button 'Add'
    expect(listed_groups).to eq(['Base questions', 'Theme questions', 'Spare questions'])
    expect(page).to have_link('Edit', href: %r{/question_groups/#{spare.id}/edit})
    click_button 'Save'
    expect(page).to have_content('Saved')
    expect(saved_groups).to eq(['Base questions', 'Theme questions', 'Spare questions'])
  end
end
