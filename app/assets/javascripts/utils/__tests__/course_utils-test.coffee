jest.dontMock '../course_utils.coffee'

describe 'CourseUtils.generateTempId', ->
  it 'creates a slug from term, title and schoo', ->
    CourseUtils = require '../course_utils.coffee'
    course =
      term: 'Fall 2015'
      school: 'University of Wikipedia'
      title: 'Introduction to Editing'
    slug = CourseUtils.generateTempId(course)
    expect(slug).toBe 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'
