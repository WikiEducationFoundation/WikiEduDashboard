require '../../testHelper'
McFly = require 'mcfly'
Flux = new McFly()
rewire = require 'rewire'

describe 'CourseClonedModal', ->
  CourseClonedModal = rewire '../../../app/assets/javascripts/components/overview/course_cloned_modal'
  course =
    slug: 'foo/bar_(baz)'
    school: 'foo'
    term: 'baz'
    title: 'bar'

  it 'renders a Modal', ->
    TestModal = ReactTestUtils.renderIntoDocument(
      <CourseClonedModal
        course={course}
      />
    )

    renderedModal = ReactTestUtils.findRenderedDOMComponentWithClass(TestModal, 'cloned-course')
    warnings = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestModal, 'warning')
    warnings.should.be.empty

  it 'renders an error message if state includes one', ->

    TestModal = ReactTestUtils.renderIntoDocument(
      <CourseClonedModal
        course={course}

      />
    )
    TestModal.setState( { error_message: 'test error message' })

    warnings = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestModal, 'warning')
    warnings.should.not.be.empty
    React.findDOMNode(warnings[0]).textContent.should.equal 'test error message'
