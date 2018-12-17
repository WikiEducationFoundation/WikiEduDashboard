import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';

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
    <Provider store={reduxStore} >
      <CourseClonedModal
        course={course}
        updateCourse={jest.fn()}
        updateClonedCourse={jest.fn()}
        currentUser={currentUser}
        setValid={jest.fn()}
        setInvalid={jest.fn()}
        activateValidations={jest.fn()}
        isValid
      />
    </Provider>
  );

  it('renders a Modal', () => {
    const renderedModal = TestModal.find('.cloned-course');
    expect(renderedModal).to.have.length(1);
    TestModal.setState({ error_message: null });
    const warnings = TestModal.find('.warning');
    expect(warnings).to.have.length(0);
  });
});
