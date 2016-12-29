import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import '../testHelper';
import '../../app/assets/javascripts/main';
import Course from '../../app/assets/javascripts/components/course.jsx';

describe('top-level course component', () => {
  it('loads without an error', () => {
    const courseProps = {
      location: {
        query: { enroll: 'passcode' },
        pathname: '/courses/this_school/this_course'
      },
      params: { course_school: 'this_school', course_title: 'this_course' }
    };
    global.Features = { enableGetHelpButton: true };
    const testCourse = ReactTestUtils.renderIntoDocument(
      <Course {...courseProps}>
        <div>Testing</div>
      </Course>
    );
    expect(testCourse).to.exist;
  });
});
