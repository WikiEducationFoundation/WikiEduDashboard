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

  it 'lets a facilitator add and remove a category' do
    visit "/courses/#{course.slug}/articles"
    expect(page).to have_content 'Tracked Categories'
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click
    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'

    # Re-add the same category
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click
    click_button 'Add categories'
    click_button 'OK'

    click_button 'Remove'
    expect(page).not_to have_content 'Earth'
  end

  it 'lets a facilitator add a template' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    find(:css, '#templates div[class*="option"]', text: 'Earth mass').click

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
  end

  it 'lets a facilitator add multiple categories at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'

    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click
    find(:css, '#categories input').set('Apple ')
    find(:css, '#categories div[class*="option"]', text: 'Apple', exact_text: true).click

    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'
    expect(page).to have_content 'Category:Apple'
  end

  it 'lets a facilitator add multiple categories from different wikis at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add category'
    find(:css, '#categories input').set('Earth ')
    find(:css, '#categories div[class*="option"]', text: 'Earth sciences').click

    find(:css, '.multi-wiki-selector input').set('fr')
    find(:css, '.multi-wiki-selector div[class*="option"]', text: 'fr.wikipedia.org').click

    find(:css, '#categories input').set('Apple ')
    find(:css, '#categories div[class*="option"]', text: 'fr:Matériel Apple', exact_text: true).click # rubocop:disable Layout/LineLength

    click_button 'Add categories'
    click_button 'OK'
    expect(page).to have_content 'Category:Earth'
    expect(page).to have_content 'fr:Category:Matériel_Apple'
  end

  it 'lets a facilitator add multiple templates at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    find(:css, '#templates div[class*="option"]', text: 'Earth mass').click
    find(:css, '#templates input').set('Apple ')
    find(:css, '#templates div[class*="option"]', text: 'Apple Inc.', exact_text: true).click

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
    expect(page).to have_content 'Template:Apple_Inc.'
  end

  it 'lets a facilitator add multiple templates from different wikis at once' do
    visit "/courses/#{course.slug}/articles"
    click_button 'Add template'

    find(:css, '#templates input').set('Earth ')
    find(:css, '#templates div[class*="option"]', text: 'Earth mass').click

    find(:css, '.multi-wiki-selector input').set('fr')
    find(:css, '.multi-wiki-selector div[class*="option"]', text: 'fr.wikipedia.org').click

    find(:css, '#templates input').set('Apple ')
    find(:css, '#templates div[class*="option"]', text: 'fr:Palette Apple', exact_text: true).click

    click_button 'Add Templates'
    click_button 'OK'
    expect(page).to have_content 'Template:Earth_mass'
    expect(page).to have_content 'fr:Template:Palette_Apple'
  end
end
