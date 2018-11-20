import { shallow } from 'enzyme';
import React from 'react';

import '../../testHelper';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';

describe('CourseCreator', () => {
  describe('render', () => {
    const updateCourseSpy = sinon.spy();
    const fetchCampaignSpy = sinon.spy();
    const cloneCourseSpy = sinon.spy();
    const submitCourseSpy = sinon.spy();
    const setValidSpy = sinon.spy();
    const setInvalidSpy = sinon.spy();
    const checkCourseSlugSpy = sinon.spy();
    const activateValidationsSpy = sinon.spy();

    const TestCourseCreator = shallow(
      <CourseCreator
        courseCreator={{}}
        fetchCoursesForUser={() => {}}
        cloneableCourses={['some_course']}
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
    describe('text inputs', () => {
      TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
      describe('subject', () => {
        it('updates courseActions', () => {
          TestCourseCreator.instance().updateCourse('subject', 'some subject');
          expect(updateCourseSpy).to.have.been.called;
          expect(setValidSpy).not.to.have.been.called;
        });
      });
      describe('term', () => {
        it('updates courseActions and validationActions', () => {
          TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
          TestCourseCreator.instance().updateCourse('term', 'this term');
          expect(updateCourseSpy).to.have.been.called;
          expect(setValidSpy).to.have.been.called;
        });
      });
    });
    describe('save course', () => {
      sinon.stub(TestCourseCreator.instance(), 'expectedStudentsIsValid').callsFake(() => true);
      sinon.stub(TestCourseCreator.instance(), 'dateTimesAreValid').callsFake(() => true);

      it('calls the appropriate methods on the actions', () => {
        const button = TestCourseCreator.find('.button__submit');
        button.simulate('click');
        expect(checkCourseSlugSpy).to.have.been.called;
        expect(setInvalidSpy).to.have.been.called;
      });
    });
  });
});
