import 'testHelper';
import React from 'react';
import { render } from 'enzyme';
import CourseNavbar from 'components/common/course_navbar';

describe('Timeline link', () => {
  Features = { enableGetHelpButton: true };
  const currentUser = { role: 0 };
  it('renders for a ClassroomProgramCourse', () => {
    const course = {
      type: 'ClassroomProgramCourse',
      flags: { enable_chat: true } // adds Chat link
    };
    const component = (
      <CourseNavbar
        course={course}
        location={{ pathname: 'foo/bar_(baz)' }}
        currentUser={currentUser}
      />
    );
    expect(render(component).find('#timeline-link').length).to.eq(1);
  });

  it('does not render for a BasicCourse', () => {
    const course = {
      type: 'BasicCourse'
    };
    const component = (
      <CourseNavbar
        course={course}
        location={{ pathname: 'foo/bar_(baz)' }}
        currentUser={currentUser}
      />
    );
    expect(render(component).find('#timeline-link').length).to.eq(0);
  });
});
