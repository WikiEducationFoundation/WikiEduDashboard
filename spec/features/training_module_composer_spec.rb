# frozen_string_literal: true

require 'rails_helper'

describe 'Training Module Composer', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:tmp_dir) { Rails.root.join('tmp', 'training_module_composer_feature_spec') }

  before do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    stub_const('TrainingModuleDraft::DIRNAME', tmp_dir.relative_path_from(Rails.root).to_s)
    login_as(admin)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  it 'supports the full new-draft → compose → save flow' do
    visit '/training_module_drafts'
    expect(page).to have_content('Training Module Composer')
    expect(page).to be_axe_clean

    # Create a new draft
    fill_in 'Module name', with: 'My test module'
    click_button 'Create draft'

    # We land in the composer
    expect(page).to have_content('My test module')
    expect(page).to have_content('Slides (0)')

    # Add a slide via the Add slide button
    click_button '+ Add'
    expect(page).to have_content('Slides (1)')

    # Fill in slide fields
    fill_in 'Slide title', with: 'Hello world'
    fill_in 'Markdown', with: "This is the **first** slide."

    # Preview shows rendered markdown
    within('.training_module_composer__editor__preview') do
      expect(page).to have_css('strong', text: 'first')
    end

    # Save
    click_button 'Save draft'
    expect(page).to have_content('Draft saved.')

    # Reload — draft should persist
    visit '/training_module_drafts/my-test-module'
    expect(page).to have_content('Hello world')
  end

  it 'imports slides via paste' do
    TrainingModuleDraft.new(slug: 'paste-demo', name: 'Paste demo').save
    visit '/training_module_drafts/paste-demo'

    expect(page).to have_content('Paste demo')
    expect(page).to have_content('Slides (0)')
    click_button 'Paste content'

    markdown = "## First\nFirst slide body.\n\n## Second\nSecond slide body."
    find('.training_module_composer__modal textarea').set(markdown)
    click_button 'Replace slides'

    expect(page).to have_content('Slides (2)')
    expect(page).to have_content('First')
    expect(page).to have_content('Second')
  end

  context 'with an existing module' do
    include_context 'training content fixture'

    it 'copies the module into an update draft and lists the files the update changes' do
      visit '/training_module_drafts'
      select 'Ponds (ponds)', from: 'Module'
      click_button 'Copy module'

      expect(page).to have_content('Slides (3)')
      expect(page).to have_content("#{content_path}/modules/ponds.yml")
      expect(page).to have_button('Export zip', disabled: true)
      expect(page).not_to have_css('.training_module_composer__sidebar__collision')

      # A copied slide keeps its slug, even when its title changes.
      fill_in 'Slide title', with: 'Welcome to ponds'
      expect(page).to have_field('Slide slug', with: 'pond-intro', readonly: true)
      click_button 'Save draft'
      expect(page).to have_content('Draft saved.')
      expect(page).to have_content("#{ponds_slides_path}/9101-pond-intro.yml")
      expect(page).to have_link('Export zip')
      expect(page).to be_axe_clean

      # A changed file that also changed on disk since the copy is flagged.
      write_training_file('slides/91-ponds/9101-pond-intro.yml', "#{pond_intro_text}# edited\n")
      visit current_path
      within('.training_module_composer__changes') do
        expect(page).to have_content('changed since copy')
      end

      # A slide that another module also lists says so.
      click_button 'What is a wetland?'
      expect(page).to have_content('Also used in: wetlands')
    end
  end

  it 'rejects non-admins' do
    logout(admin)
    login_as(create(:user))
    visit '/training_module_drafts'
    expect(page).not_to have_content('Training Module Composer')
  end
end
