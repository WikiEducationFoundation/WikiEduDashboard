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
        initiateConfirm={jest.fn()}
        deleteCourse={jest.fn()}
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

  it('includes a Cancel and Save New Course button', () => {
    const renderedModal = TestModal.find('.cloned-course');
    expect(renderedModal).to.have.length(1);

    const cancel = renderedModal.find('.button.light');
    expect(cancel).to.have.length(1);
    expect(cancel.prop('disabled')).to.be.undefined;

    const create = renderedModal.find('.button.dark');
    expect(create).to.have.length(1);
    expect(create.prop('disabled')).to.equal('disabled');
  });
});
