require '../testHelper'
CourseUtils = require '../../app/assets/javascripts/utils/course_utils'

describe 'CourseUtils.generateTempId', ->
  it 'creates a slug from term, title and school', ->
    course =
      term: 'Fall 2015'
      school: 'University of Wikipedia'
      title: 'Introduction to Editing'
    slug = CourseUtils.generateTempId(course)
    expect(slug).to.eq 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

  it 'trims unnecessary whitespace', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    slug = CourseUtils.generateTempId(course)
    expect(slug).to.eq 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

describe 'CourseUtils.cleanupCourseSlugComponents', ->
  it 'trims whitespace from the slug-related fields of a course object', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    updatedCourse = CourseUtils.cleanupCourseSlugComponents(course)
    expect(course.term).to.eq 'Fall 2015'
    expect(course.school).to.eq 'University of Wikipedia'
    expect(course.title).to.eq 'Introduction to Editing'
