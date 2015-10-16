jest.dontMock '../course_utils.coffee'
CourseUtils = require '../course_utils.coffee'

describe '.generateTempId', ->
  it 'creates a slug from term, title and school', ->
    course =
      term: 'Fall 2015'
      school: 'University of Wikipedia'
      title: 'Introduction to Editing'
    slug = CourseUtils.generateTempId(course)
    expect(slug).toBe 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

  it 'trims unnecessary whitespace', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    slug = CourseUtils.generateTempId(course)
    expect(slug).toBe 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

describe '.cleanupCourseSlugComponents', ->
  it 'trims whitespace from the slug-related fields of a course object', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    updatedCourse = CourseUtils.cleanupCourseSlugComponents(course)
    expect(course.term).toBe 'Fall 2015'
    expect(course.school).toBe 'University of Wikipedia'
    expect(course.title).toBe 'Introduction to Editing'
