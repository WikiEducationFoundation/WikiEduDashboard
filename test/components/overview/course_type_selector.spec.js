import '../../testHelper';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import sinon from 'sinon';

import CourseTypeSelector from '../../../app/assets/javascripts/components/overview/course_type_selector.jsx';

describe('CourseTypeSelector', () => {
  const course = {
    type: 'ClassroomProgramCourse'
  };

  it('displays the course type when not editable', () => {
    const NonEditableCourseTypeSelector = ReactTestUtils.renderIntoDocument(
      <CourseTypeSelector
        course={course}
        editable={false}
      />
    );
    const typeListing = ReactTestUtils.findRenderedDOMComponentWithTag(NonEditableCourseTypeSelector, 'div');
    expect(typeListing.textContent).to.eq('Type: ClassroomProgramCourse');
  });

  it('calls updateCourse when selection changes', () => {
    const spy = sinon.spy();
    CourseTypeSelector.__Rewire__('CourseActions', {
      updateCourse: spy
    });
    const EditableCourseTypeSelector = ReactTestUtils.renderIntoDocument(
      <CourseTypeSelector
        course={course}
        editable={true}
      />
    );
    const selector = ReactTestUtils.findRenderedDOMComponentWithTag(EditableCourseTypeSelector, 'select');
    Simulate.change(selector, { target: { value: 'VisitingScholarship' } });
    expect(spy.callCount).to.eq(1);
  });
});
