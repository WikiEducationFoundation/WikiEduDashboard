# frozen_string_literal: true

require 'rails_helper'

describe CoursesController do
  before { stub_wiki_validation }
  describe '#show' do
    let(:course) { create(:course) }
    let(:slug) { course.slug }
    let(:school) { slug.split('/')[0] }
    let(:titleterm) { slug.split('/')[1] }

    context 'for an valid course path' do
      it 'renders a 200' do
        course_params = { school: school, titleterm: titleterm }
        get :show, params: course_params
        expect(response.status).to eq(200)
      end
    end

    context 'when a spider tries index.php' do
      it 'renders a plain text 404' do
        course_params = { school: school, titleterm: titleterm, endpoint: 'index' }
        get :show, params: course_params, format: 'php'
        expect(response.status).to eq(404)
        expect(response.headers['Content-Type']).to match %r{text/plain}
      end
    end
  end

  describe '#destroy' do
    let!(:course)           { create(:course) }
    let!(:user)             { create(:test_user) }
    let!(:courses_users)    { create(:courses_user, course_id: course.id, user_id: user.id) }
    let!(:article)          { create(:article) }
    let!(:articles_courses) do
      create(:articles_course, course_id: course.id, article_id: article.id)
    end

    let!(:assignment) { create(:assignment, course_id: course.id) }
    let!(:campaigns_courses) { create(:campaigns_course, course_id: course.id) }
    let!(:week) { create(:week, course_id: course.id) }

    let!(:gradeable) do
      create(:gradeable, gradeable_item_type: 'Course', gradeable_item_id: course.id)
    end

    let!(:admin) { create(:admin, id: 2) }

    before do
      allow(controller).to receive(:current_user).and_return(admin)
      controller.instance_variable_set(:@course, course)
    end

    it 'calls update methods via WikiCourseEdits' do
      expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
      delete :destroy, params: { id: "#{course.slug}.json" }, as: :json
    end

    context 'destroy callbacks' do
      before do
        allow_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
      end

      it 'destroys associated models' do
        delete :destroy, params: { id: "#{course.slug}.json" }, as: :json

        %w[CoursesUsers ArticlesCourses CampaignsCourses].each do |model|
          expect do
            # metaprogramming for: CoursesUser.find(courses_user.id)
            Object.const_get(model).send(:find, send(model.underscore).id)
          end.to raise_error(ActiveRecord::RecordNotFound), "#{model} did not raise"
        end

        %i[assignment week gradeable].each do |model|
          expect do
            # metaprogramming for: Assigment.find(assignment.id)
            model.to_s.classify.constantize.send(:find, send(model).id)
          end.to raise_error(ActiveRecord::RecordNotFound), "#{model} did not raise"
        end
      end

      it 'returns success' do
        delete :destroy, params: { id: "#{course.slug}.json" }, as: :json
        expect(response).to be_success
      end

      it 'deletes the course' do
        delete :destroy, params: { id: "#{course.slug}.json" }, as: :json
        expect(Course.find_by_slug(course.slug)).to be_nil
      end
    end
  end

  describe '#update' do
    let(:submitted_1) { false }
    let(:submitted_2) { false }
    let!(:course) { create(:course, submitted: submitted_1) }
    let(:user) { create(:admin) }
    let!(:courses_user) do
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    let(:course_params) do
      { title: 'New title',
        description: 'New description',
        start: 2.months.ago.beginning_of_day,
        end: 2.months.from_now.end_of_day,
        term: 'pizza',
        slug: 'food',
        subject: 'cooking',
        expected_students: 1,
        submitted: submitted_2,
        day_exceptions: '',
        weekdays: '0001000',
        no_day_exceptions: true }
    end
    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
    end

    it 'updates all values' do
      params = { id: course.slug, course: course_params }
      put :update, params: params, as: :json
      course_params.each do |key, value|
        # There's some variability the precision of datetimes between what
        # comes out of MySQL and a raw Ruby datetime object. So we add a bit
        # of imprecision to work around that.
        if key == :end
          expect(course.reload.send(key)).to be_within(1.second).of(value)
        else
          expect(course.reload.send(key)).to eq(value)
        end
      end
    end

    context 'setting passcode' do
      let(:course) { create(:course) }
      before { course.update_attribute(:passcode, nil) }
      it 'sets if it is nil and not in params' do
        params = { id: course.slug, course: { title: 'foo' } }
        put :update, params: params, as: :json
        expect(course.reload.passcode).to match(/[a-z]{8}/)
      end
    end

    describe 'toggling timeline' do
      it 'sets the course flag to true' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: true } }
        put :update, params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(true)
      end

      it 'sets the course flag to false' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: false } }
        put :update, params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(false)
      end
    end

    it 'raises if course is not found' do
      params = { id: 'peanut-butter', course: course_params }
      expect { put :update, params: params, as: :json }
        .to raise_error(ActionController::RoutingError)
    end

    it 'returns the new course as json' do
      params = { id: course.slug, course: course_params }
      put :update, params: params, as: :json
      # created ats differ by milliseconds, so check relevant attrs
      expect(response.body['title']).to eq(course.reload.to_json['title'])
      expect(response.body['term']).to eq(course.reload.to_json['term'])
      expect(response.body['subject']).to eq(course.reload.to_json['subject'])
    end

    context 'course is not new' do
      let(:submitted_1) { true }
      let(:submitted_2) { true }
      it 'does not announce course' do
        expect_any_instance_of(WikiCourseEdits).not_to receive(:announce_course)
        params = { id: course.slug, course: course_params }
        put :update, params: params, as: :json
      end
    end

    context 'course is new' do
      let(:submitted_2) { true }
      it 'announces course and emails the instructor' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        request.content_type = 'application/json'
        expect_any_instance_of(WikiCourseEdits).to receive(:announce_course)
        expect(CourseSubmissionMailer).to receive(:send_submission_confirmation)
        params = { id: course.slug, course: course_params }
        put :update, params: params, as: :json
      end
    end
  end

  describe '#create' do
    describe 'setting slug from school/title/term' do
      let!(:user) { create(:admin) }
      let(:expected_slug) { 'Wiki_University/How_to_Wiki_(Fall_2015)' }
      let(:role_description) { 'Professor' }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
      end

      context 'all slug params present' do
        let(:course_params) do
          { school: 'Wiki University',
            title: 'How to Wiki',
            term: 'Fall 2015',
            start: '2015-01-05',
            end: '2015-12-20',
            role_description: role_description }
        end
        it 'sets slug correctly' do
          post :create, params: { course: course_params }, as: :json
          expect(Course.last.slug).to eq(expected_slug)
        end

        it 'sets instructor role description correctly' do
          post :create, params: { course: course_params }, as: :json
          expect(CoursesUsers.last.role_description).to eq(role_description)
        end
      end

      context 'not all slug params present' do
        let(:course_params) do
          { school: 'Wiki University',
            title: 'How to Wiki' }
        end
        it 'does not set slug (and does not create course)' do
          post :create, params: { course: course_params }, as: :json
          expect(Course.all).to be_empty
        end
      end

      context 'valid lanaguage and project present' do
        let(:course_params) do
          { school: 'Wiki University',
            title: 'How to Wiki',
            term: 'Fall 2015',
            start: '2015-01-05',
            end: '2015-12-20',
            language: 'ar',
            project: 'wikibooks' }
        end

        it 'sets the non-default home_wiki' do
          post :create, params: { course: course_params }, as: :json
          expect(Course.last.home_wiki.language).to eq('ar')
          expect(Course.last.home_wiki.project).to eq('wikibooks')
        end

        it 'assigns the new course to @course' do
          post :create, params: { course: course_params }, as: :json
          expect(assigns(:course)).to be_a_kind_of(Course)
        end
      end

      context 'invalid lanaguage and project present' do
        let(:course_params) do
          { school: 'Wiki University',
            title: 'How to Wiki',
            term: 'Fall 2015',
            start: '2015-01-05',
            end: '2015-12-20',
            language: 'arrr',
            project: 'wikipirates' }
        end

        it 'renders a 404 and does not create the course' do
          post :create, params: { course: course_params }, as: :json
          expect(response.status).to eq(404)
          expect(Course.count).to eq(0)
          expect(response.body).to have_content('Invalid language/project')
        end
      end

      context 'when blank values are given for course school, title or both' do
        let(:course_params) do
          { school: ' ',
            title: '  ',
            term: 'Fall 2015',
            start: '2015-01-05',
            end: '2015-12-20',
            language: 'en',
            project: 'wikipedia' }
        end

        it 'renders a 404 and does not create the course when school is blank' do
          course_params[:title] = 'Test Title'
          post :create, params: { course: course_params }, as: :json
          expect(response.status).to eq(404)
          expect(Course.count).to eq(0)
          expect(response.body).to have_content('Blank school/title for course.')
        end

        it 'renders a 404 and does not create the course when title is blank' do
          course_params[:school] = 'Test School'
          post :create, params: { course: course_params }, as: :json
          expect(response.status).to eq(404)
          expect(Course.count).to eq(0)
          expect(response.body).to have_content('Blank school/title for course')
        end

        it 'renders a 404 and does not create the course when both school and title are blank' do
          post :create, params: { course: course_params }, as: :json
          expect(response.status).to eq(404)
          expect(Course.count).to eq(0)
          expect(response.body).to have_content('Blank school/title for course')
        end
      end

      context 'when a course with the same slug already exists' do
        let(:course_params) do
          { school: 'Wiki University',
            title: 'How to Wiki',
            term: 'Fall 2015',
            start: '2015-01-05',
            end: '2015-12-20' }
        end
        before do
          post :create, params: { course: course_params }, as: :json
        end

        it 'renders a 404 and does not create the course' do
          expect(Course.count).to eq(1)
          post :create, params: { course: course_params }, as: :json
          expect(response.status).to eq(404)
          expect(Course.count).to eq(1)
          expect(response.body).to have_content(
            'Another program called Wiki_University/How_to_Wiki_(Fall_2015) already exists'
          )
        end
      end

      describe 'timeline dates' do
        let(:course_params) do
          { title: 'New title',
            description: 'New description',
            start: 2.months.ago.beginning_of_day,
            end: 2.months.from_now.end_of_day,
            school: 'burritos',
            term: 'pizza',
            slug: 'food',
            subject: 'cooking',
            expected_students: 1,
            submitted: false,
            day_exceptions: '',
            weekdays: '0001000',
            no_day_exceptions: true }
        end
        it 'sets timeline start/end to course start/end if not in params' do
          put :create, params: { course: course_params }, as: :json
          expect(Course.last.timeline_start).to eq(course_params[:start])
          expect(Course.last.timeline_end).to be_within(1.second).of(course_params[:end])
        end
      end
    end
  end

  describe '#list' do
    let(:course) { create(:course) }
    let(:campaign) { Campaign.last }
    let(:user) { create(:admin) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    context 'when campaign is not found' do
      it 'gives a failure message' do
        params = { id: course.slug, campaign: { title: 'non-existent-campaign' } }
        post :list, params: params
        expect(response.status).to eq(404)
        expect(response.body).to match(/Sorry/)
      end
    end

    context 'when campaign is found' do
      context 'post request' do
        before do
          create(:courses_user, user_id: user.id,
                                course_id: course.id,
                                role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
          stub_chat_channel_create_success
        end

        it 'creates a CampaignsCourse' do
          params = { id: course.slug, campaign: { title: campaign.title } }
          post :list, params: params, as: :json
          last_campaign = CampaignsCourses.last
          expect(last_campaign.course_id).to eq(course.id)
          expect(last_campaign.campaign_id).to eq(campaign.id)
        end

        it 'sends an email if course has no previous campaigns' do
          expect(CourseApprovalMailer).to receive(:send_approval_notification)
          params = { id: course.slug, campaign: { title: campaign.title } }
          post :list, params: params, as: :json
        end

        it 'creates a chat channel if course has no previous campaigns' do
          expect_any_instance_of(RocketChat).to receive(:create_channel_for_course)
          params = { id: course.slug, campaign: { title: campaign.title } }
          post :list, params: params, as: :json
        end

        it 'does not send an email if course is already approved' do
          course.campaigns << create(:campaign)
          expect(CourseApprovalMailer).not_to receive(:send_approval_notification)
          params = { id: course.slug, campaign: { title: campaign.title } }
          post :list, params: params, as: :json
        end
      end

      context 'delete request' do
        let!(:campaigns_course) do
          create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
        end

        it 'deletes CampaignsCourse' do
          params = { id: course.slug, campaign: { title: campaign.title } }
          delete :list, params: params, as: :json
          expect(CampaignsCourses.find_by(course_id: course.id, campaign_id: campaign.id)).to be_nil
        end
      end
    end
  end

  describe '#tag' do
    let(:course) { create(:course) }
    let(:user)   { create(:admin) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    context 'post request' do
      let(:tag) { 'pizza' }
      it 'creates a tag' do
        params = { id: course.slug, tag: { tag: tag } }
        post :tag, params: params, as: :json
        expect(Tag.last.tag).to eq(tag)
        expect(Tag.last.course_id).to eq(course.id)
      end
    end

    context 'delete request' do
      let(:tag) { Tag.create(tag: 'pizza', course_id: course.id) }
      it 'deletes the tag' do
        params = { id: course.slug, tag: { tag: tag.tag } }
        delete :tag, params: params, as: :json
        expect { Tag.find(tag.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#needs_update' do
    render_views
    let(:course) { create(:course, needs_update: false) }
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end
    it 'sets "needs_update" to true' do
      get :needs_update, params: { id: course.slug }
      expect(course.reload.needs_update).to eq(true)
    end
  end

  describe '#notify_untrained' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:instructor) do
      create(:user, id: 5)
      create(:courses_user, user_id: 5,
                            course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      User.find(5)
    end

    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    let(:subject) { get :notify_untrained, params: { id: course.slug } }

    context 'user is admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      it 'triggers WikiEdits.notify_untrained' do
        expect_any_instance_of(WikiEdits).to receive(:notify_untrained)
        expect(subject.status).to eq(200)
      end
    end

    context 'user is instructor' do
      before do
        allow(controller).to receive(:current_user).and_return(instructor)
      end

      it 'triggers WikiEdits.notify_untrained' do
        expect_any_instance_of(WikiEdits).to receive(:notify_untrained)
        expect(subject.status).to eq(200)
      end
    end

    context 'user is not admin or instructor' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns a 401' do
        expect_any_instance_of(WikiEdits).not_to receive(:notify_untrained)
        expect(subject.status).to eq(401)
      end
    end
  end

  describe '#update_syllabus' do
    let(:course) { create(:course) }
    let(:instructor) do
      create(:user, id: 5)
      create(:courses_user, user_id: 5,
                            course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      User.find(5)
    end

    before do
      allow(controller).to receive(:current_user).and_return(instructor)
    end

    it 'saves a pdf' do
      file = fixture_file_upload('syllabus.pdf', 'application/pdf')
      post :update_syllabus, params: { id: course.id, syllabus: file }
      expect(response.status).to eq(200)
      expect(course.syllabus).not_to be_nil
    end

    it 'deletes a saved file' do
      file = fixture_file_upload('syllabus.pdf', 'application/pdf')
      course.syllabus = file
      course.save
      expect(course.syllabus.exists?).to eq(true)
      post :update_syllabus, params: { id: course.id, syllabus: 'null' }
      expect(course.syllabus.exists?).to eq(false)
    end

    it 'renders an error for disallowed file types' do
      file = fixture_file_upload('syllabus.torrent', 'application/x-bittorrent')
      post :update_syllabus, params: { id: course.id, syllabus: file }
      expect(response.status).to eq(422)
    end
  end

  describe '#delete_all_weeks' do
    let(:course) { create(:course) }
    let!(:user) { create(:admin) }
    let!(:week1) { create(:week, course_id: course.id) }
    let!(:week2) { create(:week, course_id: course.id) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
    end

    it 'deletes all the weeks' do
      expect(course.weeks.count).to eq(2)
      delete :delete_all_weeks, params: { id: course.slug }
      expect(course.weeks.count).to eq(0)
      expect(response.status).to eq(200)
    end
  end
end
