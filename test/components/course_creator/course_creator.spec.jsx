import '../../testHelper';
import sinon from 'sinon';
import _ from 'lodash';

import React from 'react';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';
import CourseActions from '../../../app/assets/javascripts/actions/course_actions.js';
import ValidationActions from '../../../app/assets/javascripts/actions/validation_actions.js';
import ServerActions from '../../../app/assets/javascripts/actions/server_actions.js';

CourseCreator.__Rewire__('ValidationStore', {
  isValid() { return true; },
  firstMessage() { }
});

describe('CourseCreator', () => {
  describe('render', () => {
    const TestCourseCreator = ReactTestUtils.renderIntoDocument(
      <CourseCreator />
    );
    it('renders a title', () => {
      const headline = ReactTestUtils.findRenderedDOMComponentWithTag(TestCourseCreator, 'h3');
      expect(headline.textContent).to.eq('Create a New Course');
    });
    describe('user courses-to-clone dropdown', () => {
      describe('state not updated', () => {
        it('does not show', () => {
          const select = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'select-container');
          expect(select.classList.contains('hidden')).to.eq(true);
        });
      });
      describe('state updated to show (and user has courses)', () => {
        it('shows', () => {
          TestCourseCreator.setState({ showCloneChooser: true });
          TestCourseCreator.setState({ user_courses: ['some_course'] });
          const select = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'select-container');
          expect(select.classList.contains('hidden')).to.eq(false);
        });
      });
    });
    describe('formStyle', () => {
      describe('not submitting', () => {
        it('is empty', () => {
          const form = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'wizard__panel');
          expect(form.style.cssText).to.be.empty;
        });
      });
      describe('submitting', () => {
        it('includes pointerEvents and opacity', () => {
          TestCourseCreator.setState({ isSubmitting: true });
          const form = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'wizard__panel');
          expect(form.style.cssText).to.eq('pointer-events: none; opacity: 0.5;');
          TestCourseCreator.setState({ isSubmitting: false });
        });
      });
    });
    describe('text inputs', () => {
      TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
      const updateCourse = sinon.spy(CourseActions, 'updateCourse');
      const setValid = sinon.spy(ValidationActions, 'setValid');
      const inputs = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestCourseCreator, 'input');
      describe('subject', () => {
        it('updates courseActions', (done) => {
          const input = _.find(inputs, (ipt) => ipt.getAttribute('id') === 'course_subject');
          input.value = 'foobar';
          Simulate.change(input);
          setImmediate(() => {
            expect(updateCourse).to.have.been.called;
            expect(setValid).not.to.have.been.called;
            done();
          });
        });
      });
      describe('term', () => {
        it('updates courseActions and validationActions', (done) => {
          TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
          const input = _.find(inputs, (ipt) => ipt.getAttribute('id') === 'course_term');
          input.value = 'foobar';
          Simulate.change(input);
          setImmediate(() => {
            expect(updateCourse).to.have.been.called;
            expect(setValid).to.have.been.called;
            done();
          });
        });
      });
    });
    describe('save course', () => {
      sinon.stub(TestCourseCreator, 'expectedStudentsIsValid', () => true);
      sinon.stub(TestCourseCreator, 'dateTimesAreValid', () => true);
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
