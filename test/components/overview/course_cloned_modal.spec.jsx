import React from 'react';
import { mount } from 'enzyme';

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
  const currentUser = {
    admin: false,
    id: 123,
    isNonstudent: true
  };
  const TestModal = mount(
    <CourseClonedModal
      course={course}
      updateCourse={jest.fn()}
      updateClonedCourse={jest.fn()}
      currentUser={currentUser}
    />
  );

  it('renders a Modal', () => {
    const renderedModal = TestModal.find('.cloned-course');
    expect(renderedModal).to.have.length(1);
    TestModal.setState({ error_message: null });
    const warnings = TestModal.find('.warning');
    expect(warnings).to.have.length(0);
  });

  it('renders an error message if state includes one', () => {
    TestModal.setState({ error_message: 'test error message' });
    const warnings = TestModal.find('.warning');
    expect(warnings).not.to.be.empty;
    expect(warnings.first().text()).to.eq('test error message');
  });
});
