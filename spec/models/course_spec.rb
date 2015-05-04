require 'rails_helper'
require 'media_wiki'
require "#{Rails.root}/lib/importers/course_importer"

describe Course, type: :model do
  it 'should update data for all courses on demand' do
    VCR.use_cassette 'wiki/course_data' do
      CourseImporter.update_all_courses(false, hash: '351')

      course = Course.all.first
      course.update_cache

      expect(course.term).to eq('Summer 2014')
      expect(course.school).to eq('University of Oklahoma')
      expect(course.user_count).to eq(12)
    end
  end

  it 'should handle MediaWiki API errors' do
    stub_request(:any, %r{.*wikipedia\.org/w/api\.php?action=liststudents.*})
      .to_raise(MediaWiki::APIError.new('foo', 'bar'))
    CourseImporter.update_all_courses(false, { first: '798', second: '800' })

    course = create(:course, id: 519)
    course.manual_update
  end

  it 'should seek data for all possible courses' do
    VCR.use_cassette 'wiki/initial' do
      expect(Course.all.count).to eq(0)
      # This should check for course_ids up to 5.
      CourseImporter.update_all_courses(true, hash: 5)
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
      expect(course.users.role('instructor').first.is_instructor(course)).to be true

      # Check views
      expect(course.view_sum).to be >= 46_200
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
             start: '2015-01-01'.to_date,
             end: '2015-07-01'.to_date,
             title: 'Underwater basket-weaving',
             listed: true
      )

      CourseImporter.update_all_courses(false, { hash: '351', hash: '590' })
      course = Course.find(589)
      expect(course.listed).to be false
    end
  end

  it 'should unlist courses that have been deleted from Wikipedia' do
    VCR.use_cassette 'wiki/course_list_deleted' do
      create(:course,
             id: 9999,
             start: '2015-01-01'.to_date,
             end: '2015-07-01'.to_date,
             title: 'Underwater basket-weaving',
             listed: true
      )

      CourseImporter.update_all_courses(false, hash: '351', hash: '9999')
      course = Course.find(9999)
      expect(course.listed).to be false
    end
  end

  it 'should remove users who have been unenrolled from a course' do
    build(:course,
          id: 1,
          start: '2015-01-01'.to_date,
          end: '2015-07-01'.to_date,
          title: 'Underwater basket-weaving'
    ).save

    build(:user,
          id: 1,
          wiki_id: 'Ragesoss'
    ).save
    build(:user,
          id: 2,
          wiki_id: 'Ntdb'
    ).save

    build(:courses_user,
          id: 1,
          course_id: 1,
          user_id: 1
    ).save
    build(:courses_user,
          id: 2,
          course_id: 1,
          user_id: 2
    ).save

    # Add an article edited by user 2.
    create(:article,
           id: 1
    )
    create(:revision,
           user_id: 2,
           date: '2015-02-01'.to_date, 
           article_id: 1
    )
    create(:articles_course,
           article_id: 1,
           course_id: 1
    )

    course = Course.all.first
    expect(course.users.count).to eq(2)
    expect(CoursesUsers.all.count).to eq(2)
    expect(course.articles.count).to eq(1)

    # Do an import with just user 1, triggering removal of user 2.
    data = { '1' => {
      'student' => [{ 'id' => '1', 'username' => 'Ragesoss' }]
    } }
    CourseImporter.import_assignments data

    course = Course.all.first
    expect(course.users.count).to eq(1)
    expect(CoursesUsers.all.count).to eq(1)
    expect(course.articles.count).to eq(0)
  end

  it 'should cache revision data for students' do
    build(:user,
          id: 1,
          wiki_id: 'Ragesoss'
    ).save

    build(:course,
          id: 1,
          start: '2015-01-01'.to_date,
          end: '2015-07-01'.to_date,
          title: 'Underwater basket-weaving'
    ).save

    build(:article,
          id: 1,
          title: 'Selfie',
          namespace: 0
    ).save

    build(:revision,
          id: 1,
          user_id: 1,
          article_id: 1,
          date: '2015-03-01'.to_date,
          characters: 9000,
          views: 1234
    ).save

    # Assign the article to the user.
    build(:assignment,
          course_id: 1,
          user_id: 1,
          article_id: 1,
          article_title: 'Selfie'
    ).save

    # Make a course-user and save it.
    build(:courses_user,
          id: 1,
          course_id: 1,
          user_id: 1,
          assigned_article_title: 'Selfie'
    ).save

    # Make an article-course.
    build(:articles_course,
          id: 1,
          article_id: 1,
          course_id: 1
    ).save

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
                   slug: 'History_Class'
    )
    expect(course.to_param).to eq('History_Class')
  end

  describe '#url' do
    it 'should return the url of a course page' do
      course = build(:course,
                     slug: 'UW Bothell/Conservation Biology (Winter 2015)'
      )
      url = course.url
      # rubocop:disable Metrics/LineLength
      expect(url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Education_Program:UW_Bothell/Conservation_Biology_(Winter_2015)")
      # rubocop:enable Metrics/LineLength
    end
  end
end
