# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/watchlist_edits"

# Private courses are visible only to admins and the course's participants.
# These endpoints load courses some other way than the course page, so each
# one is checked here against the same rule.
describe 'Private course visibility', type: :request do
  let(:student) { create(:user, username: 'PrivateStudent') }
  let(:instructor) { create(:user, username: 'PrivateInstructor') }
  let(:outsider) { create(:user, username: 'Outsider') }
  let(:admin) { create(:admin) }
  let(:campaign) { Campaign.first }
  let(:private_course) do
    create(:course, slug: 'Hidden_School/Hidden_Course_(term)', title: 'Hidden Course',
                    private: true, submitted: false, start: 1.week.ago, end: 1.month.from_now)
  end
  let(:article) { create(:article, title: 'Private_Course_Article') }

  before do
    create(:courses_user, course: private_course, user: student,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, course: private_course, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:articles_course, course: private_course, article:, tracked: true)
  end

  def lists_private_course?
    response.body.include?('Hidden_Course')
  end

  describe 'courses by wiki' do
    let(:path) { '/courses_by_wiki/en.wikipedia.org.json' }

    it 'leaves the course out for a logged-out visitor' do
      get path
      expect(lists_private_course?).to be false
    end

    it 'includes the course for an admin' do
      login_as admin
      get path
      expect(lists_private_course?).to be true
    end
  end

  describe 'unsubmitted courses' do
    it 'leaves the course out for a logged-out visitor' do
      get '/unsubmitted_courses'
      expect(response.status).to eq(200)
      expect(lists_private_course?).to be false
    end

    it 'includes the course for an admin' do
      login_as admin
      get '/unsubmitted_courses'
      expect(lists_private_course?).to be true
    end
  end

  describe 'an instructor\'s taught courses' do
    let(:path) { "/users/#{instructor.username}/taught_courses_articles.json" }

    it 'leaves the course out for a logged-out visitor' do
      get path
      expect(lists_private_course?).to be false
    end

    it 'includes the course for a participant' do
      login_as student
      get path
      expect(lists_private_course?).to be true
    end
  end

  describe 'finding a course by id' do
    it 'does not reveal the slug to a logged-out visitor' do
      get "/find_course/#{private_course.id}"
      expect(response.status).to eq(404)
    end

    it 'redirects a participant' do
      login_as student
      get "/find_course/#{private_course.id}"
      expect(response).to redirect_to("/courses/#{private_course.slug}")
    end
  end

  describe 'training progress' do
    let(:path) { '/training_modules_users.json' }

    it 'is refused to a logged-out visitor' do
      get path, params: { course_id: private_course.id }
      expect(response.status).to eq(404)
    end

    it 'is shown to a participant' do
      login_as student
      get path, params: { course_id: private_course.id, user_id: student.id }
      expect(response.status).to eq(200)
    end

    context 'when asking for another user\'s progress on a public course' do
      let(:public_course) { create(:course, slug: 'Open/Open_(term)') }
      let(:users_shown) { [] }

      before do
        training_module = create(:training_module, slug: 'tr-x', name: 'Training X', kind: 0)
        week = create(:week, course: public_course)
        create(:block, week:, training_module_ids: [training_module.id])
        create(:courses_user, course: public_course, user: instructor,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        allow(TrainingModuleDueDateManager).to receive(:new).and_wrap_original do |original, **args|
          users_shown << args[:user]
          original.call(**args)
        end
      end

      it 'shows a user who can\'t edit the course only their own progress' do
        login_as outsider
        get path, params: { course_id: public_course.id, user_id: student.id }
        expect(users_shown).to eq([outsider])
      end

      it 'shows the student\'s progress to the course instructor' do
        login_as instructor
        get path, params: { course_id: public_course.id, user_id: student.id }
        expect(users_shown).to eq([student])
      end
    end
  end

  describe 'campaign articles' do
    before do
      campaign.courses << private_course
      public_course = create(:course, slug: 'Open/Open_(term)')
      campaign.courses << public_course
      create(:articles_course, course: public_course, tracked: true,
                               article: create(:article, title: 'Public_Course_Article'))
    end

    it 'leaves out articles edited only in the private course' do
      get "/campaigns/#{campaign.slug}/articles.json"
      expect(response.status).to eq(200)
      expect(response.body).to include('Public_Course_Article')
      expect(response.body).not_to include('Private_Course_Article')
    end
  end

  describe 'ORES plot' do
    after { FileUtils.rm_rf "#{Rails.root}/tmp/ores_plot" }

    it 'is refused to a logged-out visitor' do
      get "/courses/#{private_course.slug}/ores_plot.json"
      expect(response.status).to eq(404)
    end

    it 'is shown to a participant' do
      login_as student
      get "/courses/#{private_course.slug}/ores_plot.json"
      expect(response.status).to eq(200)
    end
  end

  describe 'active courses' do
    before { private_course.update(end: 1.day.from_now) }

    it 'leaves the course out for a logged-out visitor' do
      get '/active_courses.json'
      expect(response.status).to eq(200)
      expect(lists_private_course?).to be false
    end
  end

  describe 'embedded course stats' do
    let(:path) { "/embed/course_stats/#{private_course.slug}" }

    it 'are refused to a logged-out visitor' do
      get path
      expect(response.status).to eq(404)
    end

    it 'are shown to a participant' do
      login_as student
      get path
      expect(response.status).to eq(200)
    end
  end

  describe 'course report CSVs' do
    it 'are refused to a signed-in user who is not a participant' do
      expect(ReportCsvWorker).not_to receive(:generate_csv)
      login_as outsider
      get '/course_students_csv', params: { course: private_course.slug, format: :json }
      expect(response.status).to eq(404)
    end

    it 'are generated for a participant' do
      expect(ReportCsvWorker).to receive(:generate_csv)
      login_as instructor
      get '/course_students_csv', params: { course: private_course.slug, format: :json }
    end
  end

  describe 'survey preview' do
    let(:survey) { create(:survey) }

    it 'leaves private courses out of the course list' do
      get "/surveys/#{survey.id}", params: { preview: true }
      expect(response.status).to eq(200)
      expect(lists_private_course?).to be false
    end

    it 'refuses a private course named by slug' do
      get "/surveys/#{survey.id}", params: { preview: true, course_slug: private_course.slug }
      expect(response.status).to eq(404)
    end
  end

  describe 'adding students to a watchlist' do
    let(:path) { "/courses/#{private_course.slug}/students/add_to_watchlist" }

    it 'is refused to a signed-in user who can\'t edit the course' do
      expect(WatchlistEdits).not_to receive(:new)
      login_as outsider
      post path
      expect(response.status).to eq(401)
    end

    it 'is allowed for the course instructor' do
      watchlist = instance_double(WatchlistEdits, watch_userpages: 'ok')
      allow(WatchlistEdits).to receive(:new).and_return(watchlist)
      login_as instructor
      post path
      expect(response.status).to eq(200)
    end
  end
end
