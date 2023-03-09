import { shallow } from 'enzyme';
import React from 'react';

import '../../testHelper';
import { CourseCreator } from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';

describe('CourseCreator', () => {
  describe('render', () => {
    const updateCourseSpy = jest.fn();
    const fetchCampaignSpy = jest.fn();
    const cloneCourseSpy = jest.fn();
    const submitCourseSpy = jest.fn();
    const setValidSpy = jest.fn();
    const setInvalidSpy = jest.fn();
    const checkCourseSlugSpy = jest.fn();
    const activateValidationsSpy = jest.fn();

    const TestCourseCreator = shallow(
      <CourseCreator
        courseCreator={{}}
        fetchCoursesForUser={() => { }}
        cloneableCourses={['some_course']}
        assignmentsWithoutUsers={['some_course']}
        course={reduxStore.getState().course}
        updateCourse={updateCourseSpy}
        fetchCampaign={fetchCampaignSpy}
        cloneCourse={cloneCourseSpy}
        submitCourse={submitCourseSpy}
        loadingUserCourses={false}
        setValid={setValidSpy}
        setInvalid={setInvalidSpy}
        checkCourseSlug={checkCourseSlugSpy}
        activateValidations={activateValidationsSpy}
        isValid
        validations={{}}
      />
    );

    it('renders a title', () => {
      expect(TestCourseCreator.find('h3').first().text()).toEqual('Create a New Course');
    });
    describe('text inputs', () => {
      TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
      describe('subject', () => {
        it('updates courseActions', () => {
          TestCourseCreator.instance().updateCourse('subject', 'some subject');
          expect(updateCourseSpy).toBeCalled();
          expect(setValidSpy).not.toBeCalled();
        });
      });
      describe('term', () => {
        it('updates courseActions and validationActions', () => {
          TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
          TestCourseCreator.instance().updateCourse('term', 'this term');
          expect(updateCourseSpy).toBeCalled();
          expect(setValidSpy).toBeCalled();
        });
      });
    });
    describe('save course', () => {
      sinon.stub(TestCourseCreator.instance(), 'expectedStudentsIsValid').callsFake(() => true);
      sinon.stub(TestCourseCreator.instance(), 'dateTimesAreValid').callsFake(() => true);

      it('calls the appropriate methods on the actions', () => {
        const button = TestCourseCreator.find('.button__submit');
        button.simulate('click');
        expect(checkCourseSlugSpy).toBeCalled();
        expect(setInvalidSpy).toBeCalled();
      });
    });
  });
});
