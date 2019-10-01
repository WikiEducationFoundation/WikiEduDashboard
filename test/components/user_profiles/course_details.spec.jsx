import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import '../../testHelper';

import CourseDetails from '../../../app/assets/javascripts/components/user_profiles/course_details.jsx';

describe('CourseDetails', () => {
  it('lists the course', () => {
    const courses = [{
      course_id: 6,
      course_school: 'Test',
      course_slug: 'Test/Test',
      course_term: '',
      course_title: 'courseTitle1',
      user_count: 17,
      user_role: 'Student',
    },
    {
      course_id: 3,
      course_school: 'Test',
      course_slug: 'Test/Test',
      course_term: '',
      course_title: 'courseTitle2',
      user_count: 10,
      user_role: 'Instructor',
    }];

    const TestCourseDetails = ReactTestUtils.renderIntoDocument(
      <div>
        <CourseDetails courses={courses} />
      </div>
    );
    expect(TestCourseDetails.textContent).toContain('courseTitle1');
    expect(TestCourseDetails.textContent).toContain('courseTitle2');
  });
});
