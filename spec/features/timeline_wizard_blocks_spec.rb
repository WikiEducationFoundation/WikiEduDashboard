# frozen_string_literal: true

require 'rails_helper'

# The admin-only standard-block picker and sandbox mode switcher in timeline
# edit mode. Both exist because the assignment wizard only runs once, at course
# creation, and there was previously no way back into its content afterwards.
describe 'standard wizard blocks in the timeline', type: :feature, js: true do
  let(:start_date) { '2025-02-10'.to_date } # a Monday
  let(:course) do
    create(:course, start: start_date, end: start_date + 3.months,
                    timeline_start: start_date, timeline_end: start_date + 3.months,
                    weekdays: '0101010', submitted: true, flags: {})
  end

  def course_blocks
    Block.where(week_id: Week.where(course_id: course.id).select(:id))
  end

  before do
    TrainingModule.load_all
    page.current_window.resize_to(1920, 1080)
    stub_oauth_edit
  end

  describe 'the standard block picker' do
    before do
      week = create(:week, course:, order: 1)
      create(:block, week:, title: 'Block Title', order: 0)
      login_as create(:admin)
    end

    it 'inserts a standard block with its title, kind, modules and points' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Block Title'

      within('.week-1') { click_button 'Add Standard Block' }
      within('.add-wizard-block__panel') do
        within("[data-catalog-id='start_drafting_individually']") { click_button 'Add' }
      end

      within('.block__block-actions') { click_button 'Save' }
      expect(page).to have_content 'Start drafting your contributions'

      block = course_blocks.find_by(title: 'Start drafting your contributions')
      expect(block.kind).to eq(Block::KINDS['assignment'])
      expect(block.points).to eq(20)
      expect(block.training_module_ids).to eq([30, 15])
    end

    it 'shows the conditions a block depends on, and whether they match' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      # Wait for the catalog to arrive before auditing: an empty modal would
      # pass the accessibility check without exercising any of the rows.
      expect(page).to have_selector("[data-catalog-id='evaluate_wikipedia']")
      expect(page).to be_axe_clean

      within("[data-catalog-id='keeping_track_sandboxes']") do
        # The course has no no_sandboxes flag, so this variant is the match.
        expect(page).to have_content 'unless: no_sandboxes'
        expect(page).to have_content 'Matches'
      end
      within("[data-catalog-id='copyedit']") do
        # Nothing records whether the copyedit exercise was chosen.
        expect(page).to have_content 'Unknown'
      end
    end

    it 'moves focus into the picker, and back to its button on cancel' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      expect(page).to have_selector("[data-catalog-id='evaluate_wikipedia']")
      # Focus has to land inside the dialog for a screen reader to announce it.
      expect(page.evaluate_script('document.activeElement.className'))
        .to include('add-wizard-block__filter')

      within('.add-wizard-block__panel') { click_button 'Cancel' }
      expect(page).to have_no_selector('.add-wizard-block__panel')
      expect(page.evaluate_script('document.activeElement.className'))
        .to include('week__add-wizard-block')
    end

    it 'closes on Escape' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      expect(page).to have_selector("[data-catalog-id='evaluate_wikipedia']")
      find('.add-wizard-block__filter').send_keys(:escape)
      expect(page).to have_no_selector('.add-wizard-block__panel')
    end

    it 'moves focus to the title of an inserted block' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      within("[data-catalog-id='evaluate_wikipedia']") { click_button 'Add' }
      expect(page).to have_selector('.block.editable')
      focused_in_block = "document.activeElement.closest('.block.editable') !== null"
      expect(page.evaluate_script(focused_in_block)).to be true
    end

    it 'names each Add button after its block, for screen reader button lists' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      within("[data-catalog-id='evaluate_wikipedia']") do
        button = find_button('Add')
        expect(button['aria-labelledby'].split).to include('wizard-block-evaluate_wikipedia-title')
        expect(find('#wizard-block-evaluate_wikipedia-title').text).to eq('Evaluate Wikipedia')
      end
    end

    it 'says so when the filter matches nothing' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      expect(page).to have_selector("[data-catalog-id='evaluate_wikipedia']")
      fill_in 'Filter blocks', with: 'zzzz'
      expect(page).to have_content I18n.t('application.no_results', query: 'zzzz')
    end

    it 'does not offer handouts blocks, whose content is generated' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      within("[data-catalog-id='handouts_from_list']") do
        expect(page).to have_button('Add', disabled: true)
      end
    end

    it 'filters the catalog by title' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      fill_in 'Filter blocks', with: 'peer review'
      expect(page).to have_selector("[data-catalog-id='peer_review_one']")
      expect(page).to have_no_selector("[data-catalog-id='evaluate_wikipedia']")
    end

    it 'keeps the embedded demo videos when a block carrying them is inserted' do
      visit "/courses/#{course.slug}/timeline"
      within('.week-1') { click_button 'Add Standard Block' }
      within('.add-wizard-block__panel') do
        within("[data-catalog-id='moving_to_mainspace_individually']") { click_button 'Add' }
      end
      # The rich text editor parses the block's markup, so the iframes must
      # survive being loaded into it as well as being saved. Wait for the
      # block's prose first: the editor is a lazily-loaded chunk, so asserting
      # straight on the iframes races its arrival. (The title is not usable for
      # this — an inserted block opens in edit mode, where the title is an
      # input value rather than page text.)
      expect(page).to have_content 'Demo: moving work from a sandbox'
      expect(page).to have_selector('.wysiwyg-editor__content iframe')

      within('.block__block-actions') { click_button 'Save' }
      block = course_blocks.find_by(title: 'Begin moving your work to Wikipedia')
      expect(block.content).to include('<iframe')
    end
  end

  describe 'for a non-admin with edit permissions' do
    let(:instructor) { create(:user) }

    before do
      week = create(:week, course:, order: 1)
      create(:block, week:, title: 'Block Title', order: 0)
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      login_as instructor
    end

    it 'offers the ordinary Add Block but not the standard block picker' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_button 'Add Block'
      expect(page).to have_no_button 'Add Standard Block'
      expect(page).to have_no_content I18n.t('timeline.sandbox_mode')
    end
  end

  describe 'the sandbox mode switcher' do
    before do
      weeks = (1..8).map { |n| create(:week, course:, order: n) }
      create(:block, week: weeks[2], title: 'Keeping track of your work', order: 1)
      create(:block, week: weeks[4], title: 'Start drafting your contributions', order: 1)
      Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_individually')
      login_as create(:admin)
    end

    it 'switches the flag, the tag and the timeline blocks together' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Start drafting your contributions'
      expect(page).to be_axe_clean

      click_button I18n.t('timeline.sandbox_mode_switch_to_live')
      within('.confirm-modal') do
        # The dialog is named by the action it confirms, not by a generic question.
        expect(page).to have_content I18n.t('timeline.sandbox_mode_switch_to_live')
        click_button I18n.t('application.confirm')
      end

      # Scoped to the weeks: the switcher's own report also names the block it
      # removed, so a page-wide assertion would match that instead.
      within('.timeline__weeks') do
        expect(page).to have_content 'Start editing your article'
        expect(page).to have_no_content 'Start drafting your contributions'
      end
      # The report is a live region, so a screen reader hears the outcome, and
      # focus comes back to the button that started the switch.
      within('.sandbox-mode [role="status"]') do
        expect(page).to have_content I18n.t('timeline.sandbox_mode_removed')
      end
      focused_in_switcher = "document.activeElement.closest('.sandbox-mode') !== null"
      expect(page.evaluate_script(focused_in_switcher)).to be true
      expect(course.reload.no_sandboxes?).to be true
      expect(Tag.find_by(course_id: course.id, key: 'sandboxes').tag).to eq('no_sandboxes')
    end
  end
end
