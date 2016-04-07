import '../../testHelper';

import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils from 'react-addons-test-utils';
import CourseCreator from '../../../app/assets/javascripts/components/course_creator/course_creator.jsx';

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
  });
});
