# frozen_string_literal: true

require 'rails_helper'

describe 'verifying the article for an article_title_input exercise', type: :feature, js: true do
  let(:student) { create(:user, username: 'Ragesock') }
  let(:course) do
    create(:course, weekdays: '1111111', start: 1.month.ago, end: 1.month.from_now,
                    timeline_start: 1.month.ago, timeline_end: 1.month.from_now)
  end
  let(:week) { create(:week, course:) }
  let(:training_module) { TrainingModule.find_by(slug: 'update-a-biography-exercise') }
  let(:edited_title) { 'Marie Curie' }

  before do
    ActionController::Base.allow_forgery_protection = true
    TrainingModule.load_all
    create(:block, week:, training_module_ids: [training_module.id])
    course.campaigns << Campaign.first
    course.users << student
    allow_any_instance_of(WikiApi).to receive(:title_of_article_edited_by)
      .and_return(edited_title)
  end

  after do
    ActionController::Base.allow_forgery_protection = false
  end

  it 'lets a student verify from the course timeline' do
    create(:training_modules_users, user: student, training_module:,
                                    completed_at: Time.zone.now)
    login_as student
    visit "/courses/#{course.slug}/timeline"

    click_button 'Submit Article'
    fill_in placeholder: /Marie Curie/, with: 'https://en.wikipedia.org/wiki/Marie_Curie'
    click_button 'Verify'

    expect(page).to have_link 'Marie Curie', href: 'https://en.wikipedia.org/wiki/Marie_Curie'
  end

  it 'lets a student verify from the last training slide' do
    login_as student
    visit '/training/students/update-a-biography-exercise/update-a-bio-complete'

    click_button 'Submit Article'
    fill_in placeholder: /Marie Curie/, with: 'Marie Curie'
    click_button 'Verify'

    expect(page).to have_content 'Done'
    expect(TrainingModulesUsers.find_by(user: student, training_module:)
                               .exercise_article_title(course.id)).to eq('Marie Curie')
  end

  it 'shows instructors the verified article in the student drawer' do
    tmu = create(:training_modules_users, user: student, training_module:,
                                          completed_at: Time.zone.now)
    tmu.store_exercise_article_title('Marie Curie', course.id)
    tmu.save
    instructor = create(:user, username: 'Instructor', permissions: User::Permissions::INSTRUCTOR)
    create(:courses_user, course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    stub_token_request
    login_as instructor

    visit "/courses/#{course.slug}"
    click_link 'Students'
    within('#users') { page.find('.name', text: student.username).click }
    within('tr.students-exercise') { page.find('button').click }

    expect(page).to have_link 'Marie Curie', href: 'https://en.wikipedia.org/wiki/Marie_Curie'
  end
end
