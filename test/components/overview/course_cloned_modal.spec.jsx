import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import ReactDOM from 'react-dom';
import '../../testHelper';
import CourseClonedModal from '../../../app/assets/javascripts/components/overview/course_cloned_modal.jsx';

describe('CourseClonedModal', () => {
  const course = {
    slug: 'foo/bar_(baz)',
    school: 'foo',
    term: 'baz',
    title: 'bar',
    expected_students: 0
  };

  it('renders a Modal', () => {
    const TestModal = ReactTestUtils.renderIntoDocument(
      <CourseClonedModal
        course={course}
      />
    );

    const renderedModal = ReactTestUtils.findRenderedDOMComponentWithClass(TestModal, 'cloned-course');
    expect(renderedModal).not.to.be.empty;
    TestModal.setState({ error_message: null });
    const warnings = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestModal, 'warning');
    expect(warnings).to.be.empty;
  });

  it('renders an error message if state includes one', () => {
    const TestModal = ReactTestUtils.renderIntoDocument(
      <CourseClonedModal
        course={course}
      />
    );
    TestModal.setState({ error_message: 'test error message' });

    const warnings = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestModal, 'warning');
    expect(warnings).not.to.be.empty;
    expect(ReactDOM.findDOMNode(warnings[0]).textContent).to.eq('test error message');
  });
});
