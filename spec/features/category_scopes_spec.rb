# frozen_string_literal: true

require 'rails_helper'

describe 'Tracked categories and templates', js: true do
  let(:course) { create(:course, type: 'ArticleScopedProgram') }
  let(:user) { create(:user) }

  before do
    JoinCourse.new(course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as user
    stub_oauth_edit
  end

  def choose_select_option(selector, option_text, **match_opts)
    # Wait for the react-select loading indicator to disappear before looking for the option
    expect(page).to have_no_css("#{selector} div[class*='loadingIndicator']", wait: 15)

    tries = 0
    begin
      find(:css, "#{selector} div[class*='option']", text: option_text, wait: 15, **match_opts).click
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      tries += 1
      retry if tries < 3
      raise
    end
  end

  it 'lets a facilitator add and remove a category' do
    visit "/courses/#{course.slug}/articles"
    expect(page).to have_content 'Tracked Categories'
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    choose_select_option('#categories', 'Earth sciences')
    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'

    # Re-add the same category
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    choose_select_option('#categories', 'Earth sciences')
    click_button 'Add categories'
    click_button 'OK'

    click_button 'Remove'
    expect(page).not_to have_content 'Earth'
  end

  it 'lets a facilitator add a template' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    choose_select_option('#templates', 'Earth mass')

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
  end

  it 'lets a facilitator add multiple categories at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'

    find(:css, '#categories input').set('Earth ')
    choose_select_option('#categories', 'Earth sciences')
    find(:css, '#categories input').set('Apple Inc. ')
    choose_select_option('#categories', 'en:Apple Inc.', exact_text: true)

    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'
    expect(page).to have_content 'Category:Apple_Inc.'
  end

  it 'lets a facilitator add multiple categories from different wikis at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    choose_select_option('#categories', 'Earth sciences')

    find(:css, '.multi-wiki-selector input').set('fr')
    choose_select_option('.multi-wiki-selector', 'fr.wikipedia.org')

    find(:css, '#categories input').set('Matériel Apple ')
    choose_select_option('#categories', 'fr:Matériel Apple', exact_text: true)

    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'
    expect(page).to have_content 'fr:Category:Matériel_Apple'
  end

  it 'lets a facilitator add multiple templates at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    choose_select_option('#templates', 'Earth mass')
    find(:css, '#templates input').set('Apple Inc. ')
    choose_select_option('#templates', 'en:Apple Inc.', exact_text: true)

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
    expect(page).to have_content 'Template:Apple_Inc.'
  end

  it 'lets a facilitator add multiple templates from different wikis at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    choose_select_option('#templates', 'Earth mass')

    find(:css, '.multi-wiki-selector input').set('fr')
    choose_select_option('.multi-wiki-selector', 'fr.wikipedia.org')

    find(:css, '#templates input').set('Palette Apple ')
    choose_select_option('#templates', 'fr:Palette Apple', exact_text: true)

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
    expect(page).to have_content 'fr:Template:Palette_Apple'
  end

  it 'lets a facilitator add categories with different depths' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'

    find(:css, '#categories input').set('Earth ')
    choose_select_option('#categories', 'Earth sciences')
    find(:css, '#category_depth').set('3')
    find(:css, '#categories input').set('Apple Inc. ')
    choose_select_option('#categories', 'en:Apple Inc.', exact_text: true)

    expect(page).to have_content 'en:Earth sciences - 0'
    expect(page).to have_content 'en:Apple Inc. - 3'

    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'
    expect(page).to have_content 'Category:Apple_Inc.'

    # check that the category depth is saved
    depth_for_earth_sciences = Course.all.first.categories.find_by(name: 'Earth_sciences').depth
    depth_for_apple = Course.all.first.categories.find_by(name: 'Apple_Inc.').depth

    expect(depth_for_apple).to eq(3)
    expect(depth_for_earth_sciences).to eq(0)
  end
end
