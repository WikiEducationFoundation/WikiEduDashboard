# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  title             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  start             :date
#  end               :date
#  school            :string(255)
#  term              :string(255)
#  character_sum     :integer          default(0)
#  view_sum          :integer          default(0)
#  user_count        :integer          default(0)
#  article_count     :integer          default(0)
#  revision_count    :integer          default(0)
#  slug              :string(255)
#  listed            :boolean          default(TRUE)
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text(65535)
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(255)      default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#  order             :integer          default(1), not null
#  no_day_exceptions :boolean          default(FALSE)
#  trained_count     :integer          default(0)
#  cloned_status     :integer
#

require 'rails_helper'
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"

describe Course, type: :model do
  it 'should update data for all courses on demand' do
    VCR.use_cassette 'wiki/course_data' do
      LegacyCourseImporter.update_all_courses(false, cohort: [351])

      course = Course.first
      course.update_cache

      expect(course.term).to eq('Summer 2014')
      expect(course.school).to eq('University of Oklahoma')
      expect(course.user_count).to eq(12)
    end
  end

  it 'should handle MediaWiki API errors' do
    error = MediawikiApi::ApiError.new
    stub_request(:any, %r{.*wikipedia\.org/w/api\.php.*})
      .to_raise(error)
    LegacyCourseImporter.update_all_courses(false, cohort: [798, 800])

    course = create(:course, id: 519)
    course.manual_update
  end

  it 'should seek data for all possible courses' do
    VCR.use_cassette 'wiki/initial' do
      expect(Course.all.count).to eq(0)
      # This should check for course_ids up to 5.
      LegacyCourseImporter.update_all_courses(true, cohort: [5])
      # On English Wikipedia, courses 1 and 3 do not exist.
      expect(Course.all.count).to eq(3)
    end
  end

  it 'should update data for single courses' do
    VCR.use_cassette 'wiki/manual_course_data' do
      course = create(:course, id: 519)

      course.manual_update

      # Check course information
      expect(course.term).to eq('January 2015')

      # Check articles
      expect(course.articles.count).to eq(3)
      expect(Article.all.where(namespace: 0).count).to eq(course.articles.count)

      # Check users
      expect(course.user_count).to eq(6)
      expect(User.all.role('student').count).to eq(course.user_count)
      expect(course.users.role('instructor').first.instructor?(course))
        .to be true

      # Check views
      course_views = course.view_sum
      expect(course_views).to be >= 46_200
      # Run the update again, and expect view count to be the same
      # FIXME: Sometimes the initial update does not save the last available day
      # of view data, while the second update adds it. That situation can make
      # the follow check fail.

      # course.manual_update
      # course.reload
      # expect(course.view_sum).to eq(course_views)
    end
  end

  it 'should update assignments when updating courses' do
    VCR.use_cassette 'wiki/update_many_courses' do
      LegacyCourseImporter.update_all_courses(false, cohort: [351, 500, 577])

      expect(Assignment.where(role: Assignment::Roles::ASSIGNED_ROLE).count).to eq(81)
      # Check that users with multiple assignments are handled properly.
      user = User.where(wiki_id: 'AndrewHamsha').first
      expect(user.assignments.assigned.count).to eq(2)
    end
  end

  it 'should perform ad-hoc course updates' do
    VCR.use_cassette 'wiki/course_data' do
      build(:course, id: '351').save

      course = Course.all.first
      course.update
      course.update_cache

      expect(course.term).to eq('Summer 2014')
      expect(course.school).to eq('University of Oklahoma')
      expect(course.user_count).to eq(12)
    end
  end

  it 'should unlist courses that have been delisted' do
    VCR.use_cassette 'wiki/course_list_delisted' do
      create(:course,
             id: 589,
             start: Time.zone.today - 1.month,
             end: Time.zone.today + 1.month,
             title: 'Underwater basket-weaving',
             passcode: 'pizza',
             listed: true)

      LegacyCourseImporter.update_all_courses(false, cohort: [351, 590])
      course = Course.find(589)
      expect(course.listed).to be false
    end
  end

  it 'should unlist courses that have been deleted from Wikipedia' do
    VCR.use_cassette 'wiki/course_list_deleted' do
      create(:course,
             id: 9999,
             start: Time.zone.today - 1.month,
             end: Time.zone.today + 1.month,
             title: 'Underwater basket-weaving',
             passcode: 'pizza',
             listed: true)

      LegacyCourseImporter.update_all_courses(false, cohort: [351, 9999])
      course = Course.find(9999)
      expect(course.listed).to be false
    end
  end

  it 'should remove users who have been unenrolled from a course' do
    build(:course,
          id: 1,
          start: Time.zone.today - 1.month,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving').save

    build(:user,
          id: 1,
          wiki_id: 'Ragesoss').save
    build(:user,
          id: 2,
          wiki_id: 'Ntdb').save

    build(:courses_user,
          id: 1,
          course_id: 1,
          user_id: 1,
          role: CoursesUsers::Roles::STUDENT_ROLE).save
    build(:courses_user,
          id: 2,
          course_id: 1,
          user_id: 2,
          role: CoursesUsers::Roles::STUDENT_ROLE).save

    # Add an article edited by user 2.
    create(:article,
           id: 1)
    create(:revision,
           user_id: 2,
           date: Time.zone.today,
           article_id: 1)
    create(:articles_course,
           article_id: 1,
           course_id: 1)

    course = Course.all.first
    expect(course.users.count).to eq(2)
    expect(CoursesUsers.all.count).to eq(2)
    expect(course.articles.count).to eq(1)

    # Do an import with just user 1, triggering removal of user 2.
    data = { '1' => {
      'student' => [{ 'id' => '1', 'username' => 'Ragesoss' }]
    } }
    LegacyCourseImporter.import_assignments data

    course = Course.all.first
    expect(course.users.count).to eq(1)
    expect(CoursesUsers.all.count).to eq(1)
    expect(course.articles.count).to eq(0)
  end

  it 'should cache revision data for students' do
    build(:user,
          id: 1,
          wiki_id: 'Ragesoss').save

    build(:course,
          id: 1,
          start: Time.zone.today - 1.month,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving').save

    build(:article,
          id: 1,
          title: 'Selfie',
          namespace: 0).save

    build(:revision,
          id: 1,
          user_id: 1,
          article_id: 1,
          date: Time.zone.today,
          characters: 9000,
          views: 1234).save

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
          course_id: 1).save

    # Update caches
    ArticlesCourses.update_all_caches
    CoursesUsers.update_all_caches
    Course.update_all_caches

    # Fetch the created CoursesUsers entry
    course = Course.all.first

    expect(course.character_sum).to eq(9000)
    expect(course.view_sum).to eq(1234)
    expect(course.revision_count).to eq(1)
    expect(course.article_count).to eq(1)
  end

  it 'should return a valid course slug for ActiveRecord' do
    course = build(:course,
                   title: 'History Class',
                   slug: 'History_Class')
    expect(course.to_param).to eq('History_Class')
  end

  describe '#url' do
    it 'should return the url of a course page' do
      # A legacy course
      lang = Figaro.env.wiki_language
      prefix = Figaro.env.course_prefix
      course = build(:course,
                     id: 618,
                     slug: 'UW Bothell/Conservation Biology (Winter 2015)')
      url = course.url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq("https://#{lang}.wikipedia.org/wiki/Education_Program:UW_Bothell/Conservation_Biology_(Winter_2015)")
      # rubocop:enable Metrics/LineLength

      # A new course
      new_course = build(:course,
                         id: 10618,
                         slug: 'UW Bothell/Conservation Biology (Winter 2016)')
      url = new_course.url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq("https://#{lang}.wikipedia.org/wiki/#{prefix}/UW_Bothell/Conservation_Biology_(Winter_2016)")
      # rubocop:enable Metrics/LineLength
    end
  end

  describe 'validation' do
    let(:id)     { Course::LEGACY_COURSE_MAX_ID + 1000 }
    let(:course) { Course.new(passcode: passcode, id: id) }
    subject { course.valid? }

    context 'non-legacy course' do
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
        id = Course::LEGACY_COURSE_MAX_ID - 1
        passcode = nil
        course = build(:course,
                       id: id,
                       passcode: passcode)
        expect(course.valid?).to eq(true)
      end
    end
  end

  describe '#user_count' do
    let!(:course) { create(:course) }
    let!(:user1)  { create(:test_user) }
    let!(:user2)  { create(:test_user) }
    let!(:cu1)    { create(:courses_user, course_id: course.id, user_id: user1.id, role: role1) }
    let!(:cu2)    { create(:courses_user, course_id: course.id, user_id: user2.id, role: role2) }
    let!(:cu3)    { create(:courses_user, course_id: course.id, user_id: user3, role: role3) }

    before  { course.update_cache }
    subject { course.user_count }

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
      it 'returns 1' do
        expect(subject).to eq(1)
      end
    end
  end

  describe '#article_count' do
    it 'should count mainspace articles edited by students' do
      course = create(:course)
      student = create(:user)
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      # mainspace article
      article = create(:article, namespace: Article::Namespaces::MAINSPACE)
      create(:revision, article_id: article.id, user_id: student.id)
      create(:articles_course, article_id: article.id, course_id: course.id)
      # non-mainspace page
      sandbox = create(:article, namespace: Article::Namespaces::TALK)
      create(:revision, article_id: sandbox.id, user_id: student.id)
      create(:articles_course, article_id: sandbox.id, course_id: course.id)

      course.update_cache
      expect(course.article_count).to eq(1)
    end
  end

  describe '#new_article_count' do
    it 'should count newly created mainspace articles' do
      course = create(:course)
      student = create(:user)
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      # mainspace article
      article = create(:article, namespace: Article::Namespaces::MAINSPACE)
      create(:revision, article_id: article.id, user_id: student.id)
      create(:articles_course, article_id: article.id, course_id: course.id,
                               new_article: true)
      # non-mainspace page
      sandbox = create(:article, namespace: Article::Namespaces::TALK)
      create(:revision, article_id: sandbox.id, user_id: student.id)
      create(:articles_course, article_id: sandbox.id, course_id: course.id,
                               new_article: true)

      course.update_cache
      expect(course.new_article_count).to eq(1)
    end
  end

  describe '#trained_count' do
    before do
      create(:user, id: 1, trained: 0)
      create(:courses_user, user_id: 1, course_id: 1, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:user, id: 2, trained: 1)
      create(:courses_user, user_id: 2, course_id: 1, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:user, id: 3, trained: 1)
      create(:courses_user, user_id: 3, course_id: 1, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    context 'after the introduction of in-dashboard training modules' do
      let(:course) do
        create(:course, id: 1, start: '2016-01-01'.to_date, end: '2016-06-01'.to_date)
      end

      it 'returns the whole student count if no training modules are assigned' do
        course.update_cache
        expect(course.trained_count).to eq(3)
      end

      xit 'returns the number of students without overdue training' do
      end
    end
    context 'before in-dashboard training modules' do
      let(:course) do
        create(:course, id: 1, start: '2015-01-01'.to_date, end: '2015-06-01'.to_date)
      end

      it 'returns the number of students who have completed on-wiki training' do
        course.update_cache
        expect(course.trained_count).to eq(2)
      end
    end
  end

  describe '.uploads' do
    before do
      create(:course, id: 1, start: 1.year.ago, end: 1.week.ago)
      create(:user, id: 1)
      create(:courses_user, user_id: 1, course_id: 1, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:commons_upload, id: 1, user_id: 1, uploaded_at: 2.week.ago)
      create(:commons_upload, id: 2, user_id: 1, uploaded_at: 2.years.ago)
      create(:commons_upload, id: 3, user_id: 1, uploaded_at: 1.day.ago)
    end
    it 'should include uploads by students during the course' do
      course = Course.find(1)
      expect(course.uploads).to include(CommonsUpload.find(1))
    end
    it 'should exclude uploads from before or after the course' do
      course = Course.find(1)
      expect(course.uploads).not_to include(CommonsUpload.find(2))
      expect(course.uploads).not_to include(CommonsUpload.find(3))
    end
  end

  describe 'callbacks' do
    let(:course) { create(:course) }
    describe '#before_save' do
      subject { course.update_attributes(course_attrs) }
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
  end
end
