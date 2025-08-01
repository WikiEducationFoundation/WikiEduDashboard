# frozen_string_literal: true
# == Schema Information
#
# Table name: courses
#
#  id                    :integer          not null, primary key
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  start                 :datetime
#  end                   :datetime
#  school                :string(255)
#  term                  :string(255)
#  character_sum         :integer          default(0)
#  view_sum              :bigint           default(0)
#  user_count            :integer          default(0)
#  article_count         :integer          default(0)
#  revision_count        :integer          default(0)
#  slug                  :string(255)
#  subject               :string(255)
#  expected_students     :integer
#  description           :text(65535)
#  submitted             :boolean          default(FALSE)
#  passcode              :string(255)
#  timeline_start        :datetime
#  timeline_end          :datetime
#  day_exceptions        :string(2000)     default("")
#  weekdays              :string(255)      default("0000000")
#  new_article_count     :integer          default(0)
#  no_day_exceptions     :boolean          default(FALSE)
#  trained_count         :integer          default(0)
#  cloned_status         :integer
#  type                  :string(255)      default("ClassroomProgramCourse")
#  upload_count          :integer          default(0)
#  uploads_in_use_count  :integer          default(0)
#  upload_usages_count   :integer          default(0)
#  syllabus_file_name    :string(255)
#  syllabus_content_type :string(255)
#  syllabus_file_size    :bigint
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#  withdrawn             :boolean          default(FALSE)
#  references_count      :integer          default(0)
#

require 'rails_helper'

describe Course, type: :model do
  let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }

  before(:all) do
    stub_wiki_validation
    TrainingModule.load_all
  end

  it 'caches revision data for students' do
    build(:user,
          id: 1,
          username: 'Ragesoss').save

    create(:course,
           id: 1,
           start: Time.zone.today - 1.month,
           end: Time.zone.today + 1.month,
           passcode: 'pizza',
           title: 'Underwater basket-weaving')

    wiki = Wiki.get_or_create(project: 'wikipedia', language: 'en')

    build(:article,
          id: 1,
          title: 'Selfie',
          average_views: 1234,
          namespace: 0).save

    create(:course_wiki_timeslice,
           course_id: 1,
           wiki:,
           character_sum: 9000,
           references_count: 5,
           revision_count: 1,
           start: 6.days.ago,
           end: 5.days.ago)

    # Assign the article to the user.
    build(:assignment,
          course_id: 1,
          user_id: 1,
          article_id: 1,
          article_title: 'Selfie').save

    # Make a course-user and save it.
    build(:courses_user,
          id: 1,
          course_id: 1,
          user_id: 1,
          assigned_article_title: 'Selfie').save

    # Make an article-course.
    build(:articles_course,
          id: 1,
          article_id: 1,
          course_id: 1,
          first_revision: 1.day.ago).save

    # Update caches
    course = described_class.all.first
    course.update_cache_from_timeslices

    expect(course.character_sum).to eq(9000)
    expect(course.references_count).to eq(5)
    expect(course.view_sum).to eq(1234)
    expect(course.revision_count).to eq(1)
    expect(course.article_count).to eq(1)
  end

  it 'returns a valid course slug for ActiveRecord' do
    course = build(:course,
                   title: 'History Class',
                   slug: 'History_Class')
    expect(course.to_param).to eq('History_Class')
  end

  it 'updates start/end times when changing course type' do
    course = create(:basic_course,
                    start: Time.zone.local(2016, 1, 1, 12, 45, 0),
                    end: Time.zone.local(2016, 1, 10, 15, 30, 0),
                    title: 'History Class')
    expect(course.end).to be_within(1.second).of(Time.zone.local(2016, 1, 10, 15, 30, 0))
    course = course.becomes!(ClassroomProgramCourse)
    course.save!
    expect(course.end).to be_within(1.second).of(Time.zone.local(2016, 1, 10, 23, 59, 59))
    course = course.becomes!(BasicCourse)
    course.save!
    expect(course.end).to be_within(1.second).of(Time.zone.local(2016, 1, 10, 23, 59, 59))
    course.end = Time.zone.local(2016, 1, 10, 15, 30, 0)
    course.save!
    expect(course.end).to be_within(1.second).of(Time.zone.local(2016, 1, 10, 15, 30, 0))
  end

  it 'updates end time to equal start time it the times are invalid' do
    course = build(:course,
                   start: Time.zone.now,
                   end: Time.zone.now - 2.months)
    course.save
    expect(course.end).to eq(course.start)
  end

  describe '#url' do
    it 'returns the url of a course page' do
      # A legacy course
      course = build(:legacy_course,
                     id: 618,
                     slug: 'UW Bothell/Conservation Biology (Winter 2015)',
                     submitted: true)
      url = course.url
      expect(url).to be_nil

      # A new course
      new_course = build(:course,
                         id: 10618,
                         slug: 'UW Bothell/Conservation Biology (Winter 2016)',
                         submitted: true)
      url = new_course.url
      expect(url).to eq('https://en.wikipedia.org/wiki/Wikipedia:Wiki_Ed/UW_Bothell/Conservation_Biology_(Winter_2016)')

      # A course that hasn't been submitted so has no on-wiki course page yet
      new_course = build(:course, submitted: false)
      expect(new_course.url).to be_nil

      # A course type without edits enabled
      new_course = build(:editathon)
      expect(new_course.url).to be_nil
    end
  end

  describe 'validation' do
    subject { course.valid? }

    let(:course) do
      described_class.new(passcode:,
                          type:,
                          start: '2013-01-01',
                          end: '2013-07-01',
                          home_wiki_id: 1)
    end

    context 'non-legacy course' do
      let(:type) { 'ClassroomProgramCourse' }

      context 'passcode nil' do
        let(:passcode) { nil }

        it "doesn't save" do
          expect(subject).to eq(false)
        end
      end

      context 'passcode empty string' do
        let(:passcode) { '' }

        it "doesn't save" do
          expect(subject).to eq(false)
        end
      end

      context 'valid passcode' do
        let(:passcode) { 'Peanut Butter' }

        it 'saves' do
          expect(subject).to eq(true)
        end
      end
    end

    context 'legacy course' do
      it 'saves nil passcode' do
        passcode = nil
        course = build(:legacy_course,
                       passcode:)
        expect(course.valid?).to eq(true)
      end
    end
  end

  describe '#user_count' do
    subject { course.user_count }

    let!(:course) { create(:course) }
    let!(:user1)  { create(:test_user, username: 'user1') }
    let!(:user2)  { create(:test_user, username: 'user2') }
    let!(:cu1)    { create(:courses_user, course_id: course.id, user_id: user1.id, role: role1) }
    let!(:cu2)    { create(:courses_user, course_id: course.id, user_id: user2.id, role: role2) }
    let!(:cu3)    { create(:courses_user, course_id: course.id, user_id: user3, role: role3) }

    before  { course.update_cache_from_timeslices }

    context 'students in course, no instructor-students' do
      let(:role1) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:role2) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:user3) { nil }
      let(:role3) { nil }

      it 'returns 2' do
        expect(subject).to eq(2)
      end
    end

    context 'one student, one instructor, one instructor-student' do
      let(:role1) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:role2) { CoursesUsers::Roles::STUDENT_ROLE }
      let(:user3) { user1.id }
      let(:role3) { CoursesUsers::Roles::INSTRUCTOR_ROLE }

      it 'returns 2' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#article_count' do
    let(:course) { create(:course) }

    it 'counts mainspace articles edited by students' do
      student = create(:user)
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      # mainspace article
      article = create(:article, namespace: Article::Namespaces::MAINSPACE)
      create(:articles_course, article_id: article.id, course_id: course.id)
      # non-mainspace page
      create(:article, namespace: Article::Namespaces::TALK)

      course.update_cache_from_timeslices
      expect(course.article_count).to eq(1)
    end
  end

  describe '#new_article_count' do
    let(:course) { create(:course, end: '2015-01-01') }

    it 'counts newly created mainspace articles' do
      student = create(:user)
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      # mainspace article
      article = create(:article, namespace: Article::Namespaces::MAINSPACE)
      create(:articles_course, article_id: article.id, course_id: course.id,
                               new_article: true)
      # non-mainspace page
      create(:article, namespace: Article::Namespaces::TALK)

      course.update_cache_from_timeslices
      expect(course.new_article_count).to eq(1)
    end
  end

  describe '#trained_count' do
    before do
      create(:user, id: 1, trained: 0)
      create(:courses_user, user_id: 1, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:user, username: 'user2', id: 2, trained: 1)
      create(:courses_user, user_id: 2, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:user, username: 'user3', id: 3, trained: 1)
      create(:courses_user, user_id: 3, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    context 'after the introduction of in-dashboard training modules' do
      let(:course) do
        create(:course, start: '2016-01-01'.to_date, end: '2016-06-01'.to_date,
                        timeline_start: '2016-01-01'.to_date, timeline_end: '2016-06-01'.to_date)
      end

      after do
        travel_back
      end

      it 'returns the whole student count if no training modules are assigned' do
        course.update_cache_from_timeslices
        expect(course.trained_count).to eq(3)
      end

      it 'returns the whole student count before assigned trainings are due' do
        week = create(:week, course:)
        create(:block, week:, training_module_ids: [1, 2])
        travel_to Time.zone.local(2016, 1, 2)
        course.update_cache_from_timeslices
        expect(course.trained_count).to eq(3)
      end

      it 'returns the count of students who are not overude on trainings' do
        week = create(:week, course:)
        create(:block, week:, training_module_ids: [1, 2])
        # User who completed all assigned modules
        create(:training_modules_users, training_module_id: 1, user_id: 1,
                                        completed_at: '2016-01-09'.to_date)
        create(:training_modules_users, training_module_id: 2, user_id: 1,
                                        completed_at: '2016-01-09'.to_date)
        # User who completed only 1 of 2 modules
        create(:training_modules_users, training_module_id: 1, user_id: 2,
                                        completed_at: '2016-01-09'.to_date)
        create(:training_modules_users, training_module_id: 2, user_id: 2,
                                        completed_at: nil)
        travel_to Time.zone.local(2016, 10, 1)
        course.update_cache_from_timeslices
        expect(course.trained_count).to eq(1)
      end
    end

    context 'before in-dashboard training modules' do
      let(:course) do
        create(:course, id: 1, start: '2015-01-01'.to_date, end: '2015-06-01'.to_date)
      end

      it 'returns the number of students who have completed on-wiki training' do
        course.update_cache_from_timeslices
        expect(course.trained_count).to eq(2)
      end
    end
  end

  describe '.uploads' do
    before do
      create(:course, id: 1, start: 1.year.ago, end: 1.week.ago)
      create(:user, id: 1)
      create(:courses_user, user_id: 1, course_id: 1, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:commons_upload, id: 1, user_id: 1, uploaded_at: 2.weeks.ago)
      create(:commons_upload, id: 2, user_id: 1, uploaded_at: 2.years.ago)
      create(:commons_upload, id: 3, user_id: 1, uploaded_at: 1.day.ago)
    end

    it 'includes uploads by students during the course' do
      course = described_class.find(1)
      expect(course.uploads).to include(CommonsUpload.find(1))
    end

    it 'excludes uploads from before or after the course' do
      course = described_class.find(1)
      expect(course.uploads).not_to include(CommonsUpload.find(2))
      expect(course.uploads).not_to include(CommonsUpload.find(3))
    end
  end

  describe '#wiki_edits_enabled?' do
    let(:course) { build(:basic_course, flags:) }
    let(:subject) { course.wiki_edits_enabled? }

    context 'when the :wiki_edits_enabled flag is set false' do
      let(:flags) { { wiki_edits_enabled: false } }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when the :wiki_edits_enabled flag is set true' do
      let(:flags) { { wiki_edits_enabled: true } }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when the :wiki_edits_enabled flag is not set' do
      let(:flags) { nil }

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end

  describe '#timeslice_update_ran?' do
    let(:course) { build(:basic_course, flags:) }
    let(:subject) { course.timeslice_update_ran? }

    context 'when the update_logs flag does not exist' do
      let(:flags) { {} }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when the update_logs flag exists but for old system' do
      let(:flags) { { 'update_logs' => { '1' => { 'error_count' => 0 } } } }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when the update_logs flag exists for timeslices system' do
      let(:flags) { { 'update_logs' => { '1' => { 'error_count' => 0, 'processed' => 10 } } } }

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end

  describe '#cloneable?' do
    let(:subject) { course.cloneable? }

    context 'for a LegacyCourse' do
      let(:course) { build(:legacy_course) }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'for a BasicCourse without the no_clone tag' do
      let(:course) { build(:basic_course) }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'for a BasicCourse with the no_clone tag' do
      let(:course) { build(:basic_course) }
      let!(:tag) { create(:tag, tag: 'no_clone', course:) }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'for a ClassroomProgramCourse with the cloneable tag' do
      let(:course) { build(:course) }
      let!(:tag) { create(:tag, tag: 'cloneable', course:) }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'for a ClassroomProgramCourse without the cloneable tag' do
      let(:course) { build(:course) }

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  describe 'callbacks' do
    let(:course) { create(:course) }

    describe '#before_save' do
      subject { course.update(course_attrs) }

      context 'params are legit' do
        let(:course_attrs) { { end: 1.year.from_now } }

        it 'succeeds' do
          expect(subject).to eq(true)
        end
      end

      context 'slug is nil' do
        let(:course_attrs) { { slug: nil } }

        it 'fails' do
          expect(subject).to eq(false)
        end
      end

      context 'title is nil' do
        let(:course_attrs) { { title: nil } }

        it 'fails' do
          expect(subject).to eq(false)
        end
      end

      context 'school is nil' do
        let(:course_attrs) { { school: nil } }

        it 'fails' do
          expect(subject).to eq(false)
        end
      end

      context 'term is nil' do
        let(:course_attrs) { { term: nil } }

        it 'fails' do
          expect(subject).to eq(false)
        end
      end
    end

    describe '#set_default_times' do
      subject do
        course.update(course_attrs)
        course
      end

      context 'end is at the beginning of day' do
        let(:course_attrs) { { end: 1.year.from_now.beginning_of_day } }

        it 'converts to end of day' do
          expect(subject.end).to be_within(1.second).of(1.year.from_now.end_of_day)
        end
      end

      context 'timeline_end is at the beginning of day' do
        let(:course_attrs) { { timeline_end: 1.year.from_now.beginning_of_day } }

        it 'converts to end of day' do
          expect(subject.timeline_end).to be_within(1.second).of(1.year.from_now.end_of_day)
        end
      end
    end
  end

  describe 'typing and validation' do
    let(:course) { create(:course) }
    let(:arbitrary_course_type) { create(:course, type: 'Foo') }

    it 'creates ClassroomProgramCourse type by default' do
      expect(course.class).to eq(ClassroomProgramCourse)
    end

    it 'allows BasicCourse type' do
      course.update(type: 'BasicCourse')
      expect(described_class.last.class).to eq(BasicCourse)
    end

    it 'allows VisitingScholarship type' do
      course.update(type: 'VisitingScholarship')
      expect(described_class.last.class).to eq(VisitingScholarship)
    end

    it 'allows Editathon type' do
      course.update(type: 'Editathon')
      expect(described_class.last.class).to eq(Editathon)
    end

    it 'allows FellowsCohort type' do
      course.update(type: 'FellowsCohort')
      expect(described_class.last.class).to eq(FellowsCohort)
    end

    it 'allows SingleUser type' do
      course.update(type: 'SingleUser')
      expect(described_class.last.class).to eq(SingleUser)
    end

    it 'does not allow creation of arbitrary types' do
      expect { arbitrary_course_type }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'does not allow updating to arbitrary types' do
      invalid_update = course.update(type: 'Bar')
      expect(invalid_update).to eq(false)
      expect(described_class.last.class).to eq(ClassroomProgramCourse)
    end

    it 'implements required methods for every course type' do
      Course::COURSE_TYPES.each do |type|
        create(:course, type:, slug: "foo/#{type}")
        course = described_class.last
        expect(course.type).to eq(type)
        # #string_prefix
        expect(course.string_prefix).to be_a(String)
        # #wiki_edits_enabled?
        expect(course.wiki_edits_enabled?).to be_in([true, false])
        # #wiki_course_page_enabled?
        expect(course.wiki_course_page_enabled?).to be_in([true, false])
        # #enrollment_edits_enabled?
        expect(course.enrollment_edits_enabled?).to be_in([true, false])
        # #assignment_edits_enabled?
        expect(course.assignment_edits_enabled?).to be_in([true, false])
        # #multiple_roles_allowed?
        expect(course.multiple_roles_allowed?).to be_in([true, false])
        # #passcode_required?
        expect(course.passcode_required?).to be_in([true, false])
        # #use_start_and_end_times
        expect(course.use_start_and_end_times).to be_in([true, false])
        # #wiki_title
        expect(course).to respond_to(:wiki_title)
        # #training_library_slug
        expect(course.training_library_slug).to be_a(String).or be_nil
      end
    end

    context 'with edit_settings flag' do
      let(:flags) do
        {
          'edit_settings' => {
            'assignment_edits_enabled' => true,
            'wiki_course_page_enabled' => true,
            'enrollment_edits_enabled' => true
          }
        }
      end

      it 'implements required methods for every course type that has edit_settings' do
        Course::COURSE_TYPES.each do |type|
          create(:course, type:, flags:, slug: "foo/#{type}")
          course = described_class.last
          expect(course.type).to eq(type)
          # #wiki_edits_enabled?
          expect(course.wiki_edits_enabled?).to be_in([true, false])
          # #wiki_course_page_enabled?
          expect(course.wiki_course_page_enabled?).to be_in([true, false])
          # #enrollment_edits_enabled?
          expect(course.enrollment_edits_enabled?).to be_in([true, false])
          # #assignment_edits_enabled?
          expect(course.assignment_edits_enabled?).to be_in([true, false])
        end
      end
    end

    context 'with academic_system flag' do
      let(:flags) do
        {
          'academic_system' => 'semester'
        }
      end

      it 'implements required methods for every course type that has academic_system' do
        Course::COURSE_TYPES.each do |type|
          create(:course, type:, flags:, slug: "foo/#{type}")
          course = described_class.last
          expect(course.academic_system).to eq('semester')
        end
      end
    end
  end

  describe '#ready_for_survey' do
    let(:survey) { create(:survey) }
    let(:campaign) { create(:campaign, title: 'Test', slug: 'test') }
    let(:survey_assignment) { create(:survey_assignment, survey_id: survey.id, published: true) }
    let(:course) { create(:course, start: course_start, end: course_end) }
    let(:course_start) { Time.zone.today - 1.month }
    let(:course_end) { Time.zone.today + 1.month }

    before do
      survey_assignment.campaigns << campaign
    end

    let(:n) { 7 }
    let(:course_scope) do
      survey_assignment.campaigns.first.courses.ready_for_survey(
        days: n,
        before:,
        relative_to:
      )
    end

    context 'when `n` days before their course end is Today' do
      let(:course_end) { Time.zone.today - n.days }
      let(:before) { true }
      let(:relative_to) { 'end' }

      it 'include the Course' do
        course.campaigns << campaign
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days after their course end is Today' do
      # By default, course end dates are end-of-day. So we shift by 1 day to test
      # the case where the course ended within the last 24 hours.
      let(:course_end) { Time.zone.today - n.days - 1.day }
      let(:before) { false }
      let(:relative_to) { 'end' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `before` their course `start` is Today' do
      let(:course_start) { Time.zone.today + n.days }
      let(:before) { true }
      let(:relative_to) { 'start' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `after` their course `start` is Today' do
      let(:course_start) { Time.zone.today - n.days }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `after` their course `start` is tomorrow' do
      let(:course_start) { Time.zone.tomorrow - n.days }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'does not include the Course' do
        course.campaigns << campaign
        course.save
        expect(course_scope.length).to eq(0)
      end
    end
  end

  describe '#will_be_ready_for_survey' do
    let(:survey) { create(:survey) }
    let(:campaign) { create(:campaign, title: 'Test', slug: 'test') }
    let(:survey_assignment) { create(:survey_assignment, survey_id: survey.id, published: true) }
    let(:course) { create(:course, start: course_start, end: course_end) }
    let(:course_start) { Time.zone.today - 1.month }
    let(:course_end) { Time.zone.today + 1.month }

    before do
      survey_assignment.campaigns << campaign
    end

    let(:n) { 7 }
    let(:course_will_be_ready_scope) do
      survey_assignment.campaigns.first.courses.will_be_ready_for_survey(
        days: n,
        before:,
        relative_to:
      )
    end

    context 'when `n` days before the course end is after Today' do
      let(:course_end) { Time.zone.today + n.days + 1.day }
      let(:before) { true }
      let(:relative_to) { 'end' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_will_be_ready_scope.length).to eq(1)
      end
    end

    context 'when `n` days before the course start is after Today' do
      let(:course_start) { Time.zone.today + n.days + 1.day }
      let(:before) { true }
      let(:relative_to) { 'start' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_will_be_ready_scope.length).to eq(1)
      end
    end

    context 'when `n` days after their course end is after Today' do
      let(:course_end) { Time.zone.today - n.days + 1.day }
      let(:before) { false }
      let(:relative_to) { 'end' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_will_be_ready_scope.length).to eq(1)
      end
    end

    context 'when `n` days after their course start is after Today' do
      let(:course_start) { Time.zone.today - n.days + 1.day }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'includes the Course' do
        course.campaigns << campaign
        course.save
        expect(course_will_be_ready_scope.length).to eq(1)
      end
    end

    context 'when `n` days after their course start is exactly Today' do
      let(:course_start) { Time.zone.today - n.days }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'does not include the Course' do
        course.campaigns << campaign
        course.save
        expect(course_will_be_ready_scope.length).to eq(0)
      end
    end
  end

  describe '#submitted_at' do
    let(:course) { create(:course) }

    context 'when the course has not been submitted' do
      it 'returns nil' do
        expect(course.submitted_at).to be_nil
      end
    end

    context 'when the course has a "submitted" tag' do
      before { create(:tag, tag: 'submitted', course:) }

      it 'returns the time the tag was added' do
        expect(course.submitted_at).to be_within(2.seconds).of(Time.zone.now)
      end
    end
  end

  describe '#approved' do
    let(:course) { create(:course) }

    context 'when the course has not been approved' do
      it 'returns nil' do
        expect(course.approved_at).to be_nil
      end
    end

    context 'when the course has a campaign' do
      before { course.campaigns << Campaign.first }

      it 'returns the time the first campaign was added' do
        expect(course.approved_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
