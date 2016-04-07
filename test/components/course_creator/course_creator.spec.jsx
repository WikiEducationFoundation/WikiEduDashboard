import '../../testHelper';
import sinon from 'sinon';
import _ from 'lodash';

import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils, { Simulate } from 'react-addons-test-utils';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';
import CourseActions from '../../../app/assets/javascripts/actions/course_actions.js';

describe('CourseCreator', () => {
  describe('render', () => {
    const TestCourseCreator = ReactTestUtils.renderIntoDocument(
      <CourseCreator />
    );
    it('renders a title', () => {
      const headline = ReactTestUtils.findRenderedDOMComponentWithTag(TestCourseCreator, 'h3');
      const h3 = ReactDOM.findDOMNode(headline);
      return expect(h3.textContent).to.eq('Create a New Course');
    });
    describe('user courses dropdown', () => {
      describe('state not updated', () => {
        it('does not show', () => {
          const select = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'select-container');
          expect(select.classList.contains('hidden')).to.eq(true);
        });
      });
      describe('state updated to show', () => {
        it('shows', () => {
          TestCourseCreator.setState({ showCourseDropdown: true });
          const select = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'select-container');
          expect(select.classList.contains('hidden')).to.eq(false);
        });
      });
    });
    describe('formStyle', () => {
      describe('not submitting', () => {
        it('is empty', () => {
          const form = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'wizard__panel');
          expect(form.style.cssText).to.be.empty();
        });
      });
      describe('submitting', () => {
        it('includes pointerEvents and opacity', () => {
          TestCourseCreator.setState({ isSubmitting: true });
          const form = ReactTestUtils.findRenderedDOMComponentWithClass(TestCourseCreator, 'wizard__panel');
          expect(form.style.cssText).to.eq('pointer-events: none; opacity: 0.5;');
        });
      });
    });
    describe('term input', () => {
      it('tells the actions to update the course', () => {
        const updateCourse = sinon.spy(CourseActions, 'updateCourse');
        TestCourseCreator.setState({ default_course_type: 'ClassroomProgramCourse' });
        const inputs = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestCourseCreator, 'input');
        const input = _.find(inputs, (ipt) => ipt.getAttribute('id') === 'course_term');
        const inputNode = ReactDOM.findDOMNode(input);
        inputNode.value = 'foobar';
        Simulate.change(inputNode);
        expect(updateCourse).to.have.been.calledOnce;
      });
    });
  });
});
