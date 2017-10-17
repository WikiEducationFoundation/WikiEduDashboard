import '../../testHelper';
import React from 'react';
import ReactTestUtils, { Simulate } from 'react-dom/test-utils';
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
    expect(typeListing.textContent).to.eq('Type: Classroom Program');
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

  it('sets timeline start and end when switching to ClassroomProgramCourse type', () => {
    const basicCourse = {
      type: 'BasicCourse',
      start: '2016-01-01',
      end: '2016-06-03'
    };

    const EditableCourseTypeSelector = ReactTestUtils.renderIntoDocument(
      <CourseTypeSelector
        course={basicCourse}
        editable={true}
      />
    );
    const selector = ReactTestUtils.findRenderedDOMComponentWithTag(EditableCourseTypeSelector, 'select');
    expect(EditableCourseTypeSelector.props.course.timeline_start).to.be.undefined;
    expect(EditableCourseTypeSelector.props.course.timeline_end).to.be.undefined;
    expect(EditableCourseTypeSelector.props.course.type).to.eq('BasicCourse');

    Simulate.change(selector, { target: { value: 'ClassroomProgramCourse' } });
    expect(EditableCourseTypeSelector.props.course.timeline_start).to.eq('2016-01-01');
    expect(EditableCourseTypeSelector.props.course.timeline_end).to.eq('2016-06-03');
    expect(EditableCourseTypeSelector.props.course.type).to.eq('ClassroomProgramCourse');
  });
});
