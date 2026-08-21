# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/app/workers/retained_editor_check_worker"

describe RetainedEditorCheckWorker do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course,
           start: 90.days.ago,
           end: 70.days.ago,
           home_wiki: wiki,
           private: false)
  end

  let(:student_retained) do
    create(:user, username: 'retained_user', registered_at: 85.days.ago)
  end
  let(:student_not_retained) do
    create(:user, username: 'inactive_user', registered_at: 85.days.ago)
  end
  let(:instructor) do
    create(:user, username: 'instructor_user', registered_at: 85.days.ago)
  end

  let!(:cu_retained) do
    create(:courses_user,
           course: course,
           user: student_retained,
           role: CoursesUsers::Roles::STUDENT_ROLE,
           retained_after_course: nil)
  end

  let!(:cu_not_retained) do
    create(:courses_user,
           course: course,
           user: student_not_retained,
           role: CoursesUsers::Roles::STUDENT_ROLE,
           retained_after_course: nil)
  end

  let!(:cu_instructor) do
    create(:courses_user,
           course: course,
           user: instructor,
           role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
           retained_after_course: nil)
  end

  def mock_response(contribs)
    instance_double(MediawikiApi::Response, data: { 'usercontribs' => contribs })
  end

  before do
    stub_wiki_validation
  end

  describe '#perform' do
    context 'when candidate users have post-course edits' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          contribs = []
          contribs << { 'user' => 'retained_user' } if usernames.include?('retained_user')
          mock_response(contribs)
        end
      end

      it 'marks retained users as true and inactive users as false' do
        described_class.new.perform

        cu_retained.reload
        cu_not_retained.reload
        cu_instructor.reload

        expect(cu_retained.retained_after_course).to be(true)
        expect(cu_retained.retained_after_course_checked_at).not_to be_nil

        expect(cu_not_retained.retained_after_course).to be(false)
        expect(cu_not_retained.retained_after_course_checked_at).not_to be_nil

        # Instructor should NOT be checked or modified
        expect(cu_instructor.retained_after_course).to be_nil
        expect(cu_instructor.retained_after_course_checked_at).to be_nil
      end
    end

    context 'when a course ended recently (< 30 days ago)' do
      let(:recent_course) do
        create(:course,
               start: 40.days.ago,
               end: 20.days.ago,
               slug: 'School/Recent_Course_(term)',
               home_wiki: wiki,
               private: false)
      end
      let(:recent_student) do
        create(:user, username: 'recent_user', registered_at: 35.days.ago)
      end
      let!(:cu_recent) do
        create(:courses_user,
               course: recent_course,
               user: recent_student,
               role: CoursesUsers::Roles::STUDENT_ROLE,
               retained_after_course: nil)
      end

      it 'skips checking recently-ended courses' do
        expect_any_instance_of(WikiApi).not_to receive(:query)
        # Only candidates from eligible courses would be checked; if we clear eligible course:
        course.update!(end: 10.days.ago)
        described_class.new.perform

        expect(cu_recent.reload.retained_after_course).to be_nil
      end
    end

    context 'when student registered before the course started (not a new editor)' do
      let(:old_account_student) do
        create(:user, username: 'old_account_user', registered_at: 200.days.ago)
      end
      let!(:cu_old_account) do
        create(:courses_user,
               course: course,
               user: old_account_student,
               role: CoursesUsers::Roles::STUDENT_ROLE,
               retained_after_course: nil)
      end

      it 'does not check or update non-new editors' do
        allow_any_instance_of(WikiApi).to receive(:query).and_return(mock_response([]))
        described_class.new.perform

        expect(cu_old_account.reload.retained_after_course).to be_nil
      end
    end

    context 'when the course is private' do
      before do
        course.update!(private: true)
      end

      it 'ignores private courses' do
        expect_any_instance_of(WikiApi).not_to receive(:query)
        described_class.new.perform

        expect(cu_retained.reload.retained_after_course).to be_nil
      end
    end

    context 'when already checked' do
      before do
        cu_retained.update!(retained_after_course: true,
                            retained_after_course_checked_at: 1.day.ago)
        cu_not_retained.update!(retained_after_course: false,
                                retained_after_course_checked_at: 1.day.ago)
      end

      it 'does not re-query already checked records' do
        expect_any_instance_of(WikiApi).not_to receive(:query)
        described_class.new.perform
      end
    end

    context 'when MediaWiki API query fails or returns nil' do
      before do
        allow_any_instance_of(WikiApi).to receive(:query).and_return(nil)
      end

      it 'leaves records as nil for future retry' do
        described_class.new.perform

        expect(cu_retained.reload.retained_after_course).to be_nil
        expect(cu_retained.retained_after_course_checked_at).to be_nil
        expect(cu_not_retained.reload.retained_after_course).to be_nil
      end
    end

    context 'with batching of more than 40 users' do
      before do
        # Clear default students
        course.courses_users.destroy_all

        50.times do |i|
          user = create(:user, username: "student_batch_#{i}", registered_at: 80.days.ago)
          create(:courses_user,
                 course: course,
                 user: user,
                 role: CoursesUsers::Roles::STUDENT_ROLE,
                 retained_after_course: nil)
        end

        allow_any_instance_of(WikiApi).to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          # Only even indexed users have edits
          active_users = usernames.select { |u| u.split('_').last.to_i.even? }
          contribs = active_users.map { |u| { 'user' => u } }
          mock_response(contribs)
        end
      end

      it 'processes all batches and correctly updates records' do
        described_class.new.perform

        expect(course.courses_users.where(retained_after_course: true).count).to eq(25)
        expect(course.courses_users.where(retained_after_course: false).count).to eq(25)
        expect(course.courses_users.where(retained_after_course: nil).count).to eq(0)
      end
    end

    context 'when MediaWiki API returns continuation pages' do
      before do
        page_count = 0
        allow_any_instance_of(WikiApi).to receive(:query) do |_instance, _params|
          page_count += 1
          if page_count == 1
            instance_double(MediawikiApi::Response, data: {
              'usercontribs' => [{ 'user' => 'retained_user' }],
              'continue' => { 'uccontinue' => '20260801000000|12345' }
            })
          else
            instance_double(MediawikiApi::Response, data: {
              'usercontribs' => [{ 'user' => 'inactive_user' }]
            })
          end
        end
      end

      it 'fetches continuation pages until all users are checked' do
        described_class.new.perform

        cu_retained.reload
        cu_not_retained.reload

        expect(cu_retained.retained_after_course).to be(true)
        expect(cu_not_retained.retained_after_course).to be(true)
      end
    end
  end
end
