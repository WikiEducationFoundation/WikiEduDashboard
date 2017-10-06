import '../../testHelper';

import React from 'react';
import { findDOMNode } from 'react-dom';
import ReactTestUtils from 'react-addons-test-utils';
import EmptyWeek from '../../../app/assets/javascripts/components/timeline/empty_week.jsx';

const makeSpacesUniform = (str) => { return str.replace(/\s{1,}/g, ' '); };

describe('EmptyWeek', () => {
  const course = { slug: 'my_course', type: 'ClassroomProgramCourse' };

  describe('empty state', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek />
    );
    it('gives the empty text if timeline and edit permissions are empty', () => {
      const headline = ReactTestUtils.findRenderedDOMComponentWithTag(TestEmptyWeek, 'h1');
      const h1 = ReactDOM.findDOMNode(headline);
      expect(h1.textContent).to.eq(I18n.t('timeline.no_activity_this_week'));
    });
  });

  describe('timeline is empty, edit permissions', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek
        emptyTimeline
        edit_permissions
        course={course}
      />
    );
    it('suggests editing the week', () => {
      const pTag = ReactTestUtils.findRenderedDOMComponentWithClass(TestEmptyWeek, 'week__no-activity__get-started');
      expect(makeSpacesUniform(pTag.textContent)).to.eq(
        makeSpacesUniform('To get started, start editing this week or use the assignment wizard to create a timeline.')
      );
    });
  });

  describe('timeline is empty, no edit permissions', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek
        emptyTimeline
      />
    );
    it('says course has no timeline', () => {
      const week = findDOMNode(TestEmptyWeek);
      expect(week.innerHTML).to.contain('This course has no timeline.');
    });
  });
});
