require 'rails_helper'

describe 'Training Navigation', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:library_id) { 'students' }
  let(:module_id)  { TrainingModule.all.first.slug }
  let(:any) { 'five-pillars' }
  
  before { TrainingModule.load_all }

  it 'renders Bread crumbs' do
    visit "/training/#{library_id}/#{module_id}/#{any}"
    expect(page).to have_selector('ol.breadcrumbs')
  end

  it 'renders TrainingHamburger' do
    visit "/training/#{library_id}/#{module_id}/#{any}"
    expect(page).to have_selector('div.training__slide__nav')
  end

  it 'renders the GetHelp Button when enable_get_help_button true',js_error_expected: true do
    login_as user
    allow(Features).to receive(:enable_get_help_button?).and_return(true)

    visit "/training/#{library_id}/#{module_id}/#{any}"
    expect(page).to have_button('Get Help')
  end

  it 'hides the GetHelp Button when enable_get_help_button is false' do
    login_as user
    allow(Features).to receive(:enable_get_help_button?).and_return(false)
    
    visit "/training/#{library_id}/#{module_id}/#{any}"
    expect(page).not_to have_button('Get Help')
  end
end
