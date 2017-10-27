import '../../testHelper';
import sinon from 'sinon';

import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';

import CourseActions from '../../../app/assets/javascripts/actions/course_actions.js';
import ValidationActions from '../../../app/assets/javascripts/actions/validation_actions.js';
import ServerActions from '../../../app/assets/javascripts/actions/server_actions.js';
import { mount } from 'enzyme';

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

const getStyle = (node) => {
  const rootTag = node.html().match(/(<.*?>)/)[1]; // grab the top tag
  const styleMatch = rootTag.match(/style="([^"]*)"/i);
  return styleMatch ? styleMatch[1] : '';
};

describe('CourseCreator', () => {
  describe('render', () => {
    const TestCourseCreator = mount(<CourseCreator fetchCoursesForUser={() => {}} user_courses={["some_course"]} />);

    it('renders a title', () => {
      expect(TestCourseCreator.find('h3').first().text()).to.eq('Create a New Course');
    });
    describe('user courses-to-clone dropdown', () => {
      describe('state not updated', () => {
        it('does not show', () => {
          expect(
            TestCourseCreator
              .find('select-container')
              .first()
              .hasClass('hidden')
          ).to.eq(true);
        });
      });
      describe('state updated to show (and user has courses)', () => {
        it('shows', () => {
          TestCourseCreator.setState({ showCloneChooser: true });
          TestCourseCreator.setState({ user_courses: ['some_course'] });
          expect(
            TestCourseCreator
              .find('select-container')
              .first()
              .hasClass('hidden')
            ).to.eq(false);
        });
      });
    });
    describe('formStyle', () => {
      describe('not submitting', () => {
        it('is empty', () => {
          expect(getStyle(TestCourseCreator)).to.eq('');
        });
      });
      describe('submitting', () => {
        it('includes pointerEvents and opacity', () => {
          TestCourseCreator.setState({ isSubmitting: true });
          const wizardPanel = TestCourseCreator.find('.wizard__panel').first();
          expect(getStyle(wizardPanel)).to.eq('pointer-events: none; opacity: 0.5;');
          TestCourseCreator.setState({ isSubmitting: false });
        });
      });
    });
    describe.only('text inputs', () => {
      TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
      const updateCourseSpy = sinon.spy(CourseActions, 'updateCourse');
      const setValidSpy = sinon.spy(ValidationActions, 'setValid');

      describe('subject', () => {
        it('updates courseActions', () => {
          const courseSubject = TestCourseCreator
            .find({ id: 'course_subject' })
            .first();

          courseSubject.simulate(
            'change',
            { target: {
              name: 'course_subject',
              value: 'some course'
            }
            });
          expect(updateCourseSpy).to.have.been.called;
          expect(setValidSpy).not.to.have.been.called;
        });
      });
      describe('term', () => {
        it('updates courseActions and validationActions', () => {
          TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
          const courseTerm = TestCourseCreator
            .find({ id: 'course_term' })
            .first();

          courseTerm.simulate('change');
          expect(updateCourseSpy).to.have.been.called;
          expect(setValidSpy).to.have.been.called;
        });
      });
    });
    describe('save course', () => {
      sinon.stub(TestCourseCreator, 'expectedStudentsIsValid').callsFake(() => true);
      sinon.stub(TestCourseCreator, 'dateTimesAreValid').callsFake(() => true);
      const checkCourse = sinon.spy(ServerActions, 'checkCourse');
      const setInvalid = sinon.spy(ValidationActions, 'setInvalid');
      it('calls the appropriate methods on the actions', () => {
        const button = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'button__submit');
        Simulate.click(button);
        expect(checkCourse).to.have.been.called;
        expect(setInvalid).to.have.been.called;
      });
    });
  });
});