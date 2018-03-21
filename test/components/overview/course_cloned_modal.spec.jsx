import React from 'react';
import { Provider } from 'react-redux';
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
  const TestModal = mount(
    <Provider store={reduxStore}>
      <CourseClonedModal
        course={course}
      />
    </Provider>
  );


  it('renders a Modal', () => {
    const renderedModal = TestModal.find('.cloned-course');
    expect(renderedModal).to.have.length(1);
  });
});
