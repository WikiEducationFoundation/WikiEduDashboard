CourseUtils = require '../../app/assets/javascripts/utils/course_utils'
should = require 'should'

describe '.generateTempId', ->
  it 'creates a slug from term, title and school', ->
    course =
      term: 'Fall 2015'
      school: 'University of Wikipedia'
      title: 'Introduction to Editing'
    slug = CourseUtils.generateTempId(course)
    slug.should.equal 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

  it 'trims unnecessary whitespace', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    slug = CourseUtils.generateTempId(course)
    slug.should.equal 'University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)'

describe '.cleanupCourseSlugComponents', ->
  it 'trims whitespace from the slug-related fields of a course object', ->
    course =
      term: ' Fall 2015'
      school: '   University of Wikipedia '
      title: ' Introduction to Editing     '
    updatedCourse = CourseUtils.cleanupCourseSlugComponents(course)
    course.term.should.equal 'Fall 2015'
    course.school.should.equal 'University of Wikipedia'
    course.title.should.equal 'Introduction to Editing'
