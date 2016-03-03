require '../../testHelper'
McFly = require 'mcfly'
Flux = new McFly()
rewire = require 'rewire'

describe 'CourseClonedModal', ->
  CourseClonedModal = rewire '../../../app/assets/javascripts/components/overview/course_cloned_modal.cjsx'
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
    expect(warnings).to.be.empty

  it 'renders an error message if state includes one', ->

    TestModal = ReactTestUtils.renderIntoDocument(
      <CourseClonedModal
        course={course}

      />
    )
    TestModal.setState( { error_message: 'test error message' })

    warnings = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestModal, 'warning')
    expect(warnings).not.to.be.empty
    expect(ReactDOM.findDOMNode(warnings[0]).textContent).to.eq 'test error message'
