import sinon from 'sinon';
import { shallow } from 'enzyme';
import React from 'react';

import '../../testHelper';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';

CourseCreator.__Rewire__('ValidationStore', {
  isValid() { return true; },
  firstMessage() { }
});

/**
* returns the style attribute applied to a given node.
  params:
    node (enzyme node) the node you would like to inspect
  returns empty string if no styles are found
**/


describe('CourseCreator', () => {
  describe('render', () => {
    const updateCourseSpy = sinon.spy();
    const fetchCampaignSpy = sinon.spy();
    const cloneCourseSpy = sinon.spy();
    const submitCourseSpy = sinon.spy();

    const TestCourseCreator = shallow(
      <CourseCreator
        courseCreator={{}}
        fetchCoursesForUser={() => {}}
        cloneableCourses={["some_course"]}
        course={reduxStore.getState().course}
        updateCourse={updateCourseSpy}
        fetchCampaign={fetchCampaignSpy}
        cloneCourse={cloneCourseSpy}
        submitCourse={submitCourseSpy}
        validations={[]}
        errorQueue={[]}
      />
    );

    it('renders a title', () => {
      expect(TestCourseCreator.find('h3').first().text()).to.eq('Create a New Course');
    });
    describe('user courses-to-clone dropdown', () => {
      describe('state not updated', () => {
        it('does not show', () => {
          expect(
            TestCourseCreator
              .find('.select-container')
              .hasClass('hidden')
          ).to.eq(true);
        });
      });
      describe('state updated to show (and user has courses)', () => {
        it('shows', () => {
          TestCourseCreator.setState({ showCloneChooser: true });
          TestCourseCreator.setState({ cloneableCourses: ['some_course'] });
          expect(
            TestCourseCreator
              .find('.select-container')
              .hasClass('hidden')
            ).to.eq(false);
        });
      });
    });
  });
});
