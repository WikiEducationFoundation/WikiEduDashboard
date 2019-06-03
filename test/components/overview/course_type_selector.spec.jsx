import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';

import '../../testHelper';
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
        updateCourse={sinon.spy()}
      />
    );
    const typeListing = ReactTestUtils.findRenderedDOMComponentWithTag(NonEditableCourseTypeSelector, 'div');
    expect(typeListing.textContent).to.eq('Type: Wikipedia Student Program');
  });

  it('calls updateCourse when selection changes ', () => {
    const spy = sinon.spy();
    const EditableCourseTypeSelector = ReactTestUtils.renderIntoDocument(
      <CourseTypeSelector
        course={course}
        editable={true}
        updateCourse={spy}
      />
    );

    const selector = ReactTestUtils.findRenderedDOMComponentWithTag(EditableCourseTypeSelector, 'input');
    selector.value = 'Editathon';
    Simulate.change(selector);
    Simulate.keyDown(selector, { key: 'Enter', keyCode: 13, which: 13 });
    expect(spy.callCount).to.eq(1);
  });
});
