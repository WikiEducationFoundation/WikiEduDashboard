import '../../testHelper';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';

import CourseTypeSelector from '../../../app/assets/javascripts/components/overview/course_type_selector.jsx';

describe('CourseTypeSelector', ()=> {
  const course = {
    type: 'ClassroomProgramCourse'
  }
  it('displays the course type when not editable', () => {
    const NonEditableCourseTypeSelector = ReactTestUtils.renderIntoDocument(
      <CourseTypeSelector
        course={course}
        editable={false} />
    );
    const type_listing = ReactTestUtils.findRenderedDOMComponentWithTag(NonEditableCourseTypeSelector, 'div');
    expect(type_listing.textContent).to.eq('Type: ClassroomProgramCourse')
  });
});
