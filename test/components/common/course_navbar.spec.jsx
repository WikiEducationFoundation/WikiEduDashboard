import 'testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import CourseNavbar from 'components/common/course_navbar';

describe('Timeline link', () => {
  Features = { enableGetHelpButton: true };
  const currentUser = { role: 0 };
  const slug = '/courses/foo/bar_(baz)';

  it('renders for a ClassroomProgramCourse', () => {
    const course = {
      type: 'ClassroomProgramCourse',
      flags: { enable_chat: true }, // adds Chat link
      title: 'bar'
    };
    const component = (
      <CourseNavbar
        course={course}
        location={{ pathname: slug }}
        currentUser={currentUser}
        courseLink={slug}
      />
    );
    // Timeline link is rendered
    expect(shallow(component).find('#timeline-link').length).to.eq(1);
    // Correct Home link is rendered
    expect(shallow(component).find('Link').nodes[0].props.to).to.eq(`${slug}/home`);
  });

  it('does not render for a BasicCourse', () => {
    const course = {
      type: 'BasicCourse'
    };
    const component = (
      <CourseNavbar
        course={course}
        location={{ pathname: slug }}
        currentUser={currentUser}
        courseLink={slug}
      />
    );
    expect(shallow(component).find('#timeline-link').length).to.eq(0);
    // Correct Home link is rendered
    expect(shallow(component).find('Link').nodes[0].props.to).to.eq(`${slug}/home`);
  });
});
