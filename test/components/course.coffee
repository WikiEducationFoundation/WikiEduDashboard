require '../testHelper'
Course = require '../../app/assets/javascripts/components/course'

# Stub ServerActions methods. Otherwise, when run as a suite, ServerActions
# makes failing AJAX requests and tails the Notifications spec
ServerActions = require '../../app/assets/javascripts/actions/server_actions'
sinon.stub(ServerActions, 'fetch')

describe 'Course', ->
  params =
    course_school: 'test'
    course_title: 'test'
  location =
    pathname: '/foo/bar/baz'
    query: ''
  TestCourse = ReactTestUtils.renderIntoDocument(
    <Course
      params={params}
      location={location}
      children={<div></div>}
    />
  )

  beforeEach ->
    TestCourse.setState
      course:
        title: 'Test Course'
      current_user:
        id: 1

  it 'renders the course title', ->
    title = ReactTestUtils.findRenderedDOMComponentWithTag(TestCourse, 'h2')
    expect(title.textContent).to.eq('Test Course')

