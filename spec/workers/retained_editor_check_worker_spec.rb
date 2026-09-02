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

  def mock_response(contribs, continue: nil)
    data = { 'usercontribs' => contribs }
    data['continue'] = continue if continue
    instance_double(MediawikiApi::Response, data: data)
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
          if usernames.include?('retained_user')
            contribs << { 'user' => 'retained_user' }
          end
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
        course.update!(end: 10.days.ago)
        described_class.new.perform

        expect(cu_recent.reload.retained_after_course).to be_nil
      end
    end

    context 'when student registered before the course started (not a new editor)' do
      let(:old_account_student) do
        create(:user, username: 'old_account_user',
                      registered_at: 200.days.ago)
      end
      let!(:cu_old_account) do
        create(:courses_user,
               course: course,
               user: old_account_student,
               role: CoursesUsers::Roles::STUDENT_ROLE,
               retained_after_course: nil)
      end

      it 'does not check or update non-new editors' do
        allow_any_instance_of(WikiApi)
          .to receive(:query).and_return(mock_response([]))
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
        cu_not_retained.update!(
          retained_after_course: false,
          retained_after_course_checked_at: 1.day.ago
        )
      end

      it 'does not re-query already checked records' do
        expect_any_instance_of(WikiApi).not_to receive(:query)
        described_class.new.perform
      end
    end

    context 'when MediaWiki API batch query fails with baduser' do
      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          if usernames.size > 1
            nil # Simulate batch failure due to invalid username
          elsif usernames.include?('retained_user')
            mock_response([{ 'user' => 'retained_user' }])
          else
            mock_response([])
          end
        end
      end

      it 'falls back to individual queries and marks users correctly' do
        described_class.new.perform

        expect(cu_retained.reload.retained_after_course).to be(true)
        expect(cu_not_retained.reload.retained_after_course).to be(false)
        expect(cu_not_retained.retained_after_course_checked_at)
          .not_to be_nil
      end
    end

    context 'when narrowed re-query finds a user beyond page 1' do
      # Issue A fix: when a prolific editor fills page 1, the narrowed
      # re-query for remaining users must actually fire.
      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          if usernames.sort == %w[inactive_user retained_user]
            # Page 1: only the prolific user's edits, with a continue token
            mock_response(
              [{ 'user' => 'retained_user' }],
              continue: { 'uccontinue' => 'actor|1|20260101|123' }
            )
          elsif usernames == ['inactive_user']
            # Narrowed re-query: finds the second user's edits
            mock_response([{ 'user' => 'inactive_user' }])
          else
            mock_response([])
          end
        end
      end

      it 're-queries with narrowed list and correctly marks both users' do
        described_class.new.perform

        expect(cu_retained.reload.retained_after_course).to be(true)
        expect(cu_not_retained.reload.retained_after_course).to be(true)
      end
    end

    context 'when continuation pages are followed for same pending set' do
      # Multi-page: a user's edits span beyond page 1 and the second
      # page reveals them.
      before do
        call_count = 0
        allow_any_instance_of(WikiApi)
          .to receive(:query) do |_instance, _params|
          call_count += 1
          if call_count == 1
            # Page 1: no matching users yet, but more pages
            mock_response(
              [],
              continue: { 'uccontinue' => 'actor|1|20260101|456' }
            )
          else
            # Page 2: finds the retained user
            mock_response([{ 'user' => 'retained_user' }])
          end
        end
      end

      it 'follows continue tokens and finds users on later pages' do
        described_class.new.perform

        expect(cu_retained.reload.retained_after_course).to be(true)
        expect(cu_not_retained.reload.retained_after_course).to be(false)
      end
    end

    context 'when transient API failure occurs during individual queries' do
      # All queries fail (API outage) — leave everything nil for retry,
      # and the circuit breaker stops processing further courses.
      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query).and_return(nil)
      end

      it 'leaves records fully nil and stops the run early' do
        described_class.new.perform

        cu_retained.reload
        cu_not_retained.reload
        expect(cu_retained.retained_after_course).to be_nil
        expect(cu_retained.retained_after_course_checked_at).to be_nil
        expect(cu_not_retained.retained_after_course).to be_nil
        expect(cu_not_retained.retained_after_course_checked_at).to be_nil
        expect(described_class.eligible_course_ids).to include(course.id)
      end
    end

    context 'when API is down across multiple courses (circuit breaker)' do
      let!(:course_2) do
        c = create(:course, slug: 'School/Course_2_(term)', start: 100.days.ago,
                            end: 80.days.ago, home_wiki: wiki, private: false)
        user2 = create(:user, username: 'student_course_2', registered_at: 95.days.ago)
        create(:courses_user, course: c, user: user2,
                              role: CoursesUsers::Roles::STUDENT_ROLE,
                              retained_after_course: nil)
        c
      end

      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query).and_return(nil)
      end

      it 'stops after the first failed course instead of hammering the API' do
        # Without circuit breaker: 1 batch + 40 individual queries per course = many calls.
        # With circuit breaker: stops after first course's batch+individual queries fail.
        # course_2 has 1 student → 1 batch query + 1 individual query = 2 calls total.
        # The main course (2 students) is never attempted.
        call_count = 0
        allow_any_instance_of(WikiApi).to receive(:query) do
          call_count += 1
          nil
        end

        described_class.new.perform

        expect(call_count).to eq(2)
        expect(CoursesUsers.where.not(retained_after_course_checked_at: nil).count).to eq(0)
      end
    end

    context 'when partial API failure in individual fallback' do
      # One user's query succeeds, another's fails. The failed user gets
      # checked_at set (stops retries) but retained_after_course stays nil.
      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          if usernames.size > 1
            nil # batch fails
          elsif usernames.include?('retained_user')
            mock_response([{ 'user' => 'retained_user' }])
          else
            nil # permanent error for inactive_user
          end
        end
      end

      it 'sets checked_at for failed user but leaves status nil' do
        described_class.new.perform

        cu_retained.reload
        cu_not_retained.reload
        expect(cu_retained.retained_after_course).to be(true)
        expect(cu_not_retained.retained_after_course).to be_nil
        expect(cu_not_retained.retained_after_course_checked_at)
          .not_to be_nil
        # Course no longer eligible since all candidates have checked_at
        expect(described_class.eligible_course_ids).not_to include(course.id)
      end
    end

    context 'with batching of more than 40 users' do
      before do
        course.courses_users.destroy_all

        50.times do |i|
          user = create(:user, username: "student_batch_#{i}",
                               registered_at: 80.days.ago)
          create(:courses_user,
                 course: course,
                 user: user,
                 role: CoursesUsers::Roles::STUDENT_ROLE,
                 retained_after_course: nil)
        end

        allow_any_instance_of(WikiApi)
          .to receive(:query) do |_instance, params|
          usernames = params[:ucuser] || []
          active = usernames.select { |u| u.split('_').last.to_i.even? }
          contribs = active.map { |u| { 'user' => u } }
          mock_response(contribs)
        end
      end

      it 'processes all batches and correctly updates records' do
        described_class.new.perform

        retained = course.courses_users
                         .where(retained_after_course: true).count
        not_retained = course.courses_users
                             .where(retained_after_course: false).count
        unchecked = course.courses_users
                          .where(retained_after_course: nil).count
        expect(retained).to eq(25)
        expect(not_retained).to eq(25)
        expect(unchecked).to eq(0)
      end
    end

    context 'when limiting course count per perform run' do
      let!(:course_2) do
        # Ends earlier than the main course (80 vs 70 days ago), so it sorts
        # first under order(:end, :id) and gets picked when limit is 1.
        c = create(:course,
                   slug: 'School/Course_2_(term)',
                   start: 100.days.ago,
                   end: 80.days.ago,
                   home_wiki: wiki,
                   private: false)
        user2 = create(:user, username: 'student_course_2',
                              registered_at: 95.days.ago)
        create(:courses_user, course: c, user: user2,
                              role: CoursesUsers::Roles::STUDENT_ROLE,
                              retained_after_course: nil)
        c
      end

      before do
        allow_any_instance_of(WikiApi)
          .to receive(:query).and_return(mock_response([]))
      end

      it 'only checks up to the limit of courses specified' do
        total_checked = described_class.new.perform(1)
        # Only course_2 (oldest end date) is checked; main course is skipped.
        expect(total_checked).to eq(1)
        expect(described_class.eligible_course_ids).to include(course.id)
        expect(described_class.eligible_course_ids).not_to include(course_2.id)
      end
    end
  end
end
