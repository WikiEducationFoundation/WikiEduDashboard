import '../../testHelper';

import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils from 'react-addons-test-utils';
import EmptyWeek from '../../../app/assets/javascripts/components/timeline/empty_week.cjsx';

const makeSpacesUniform = (str) => { return str.replace(/\s{1,}/g, ' '); };

describe('EmptyWeek', () => {
  describe('empty state', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek />
    );
    it('gives the empty text if timeline and edit permissions are empty', () => {
      const headline = ReactTestUtils.findRenderedDOMComponentWithTag(TestEmptyWeek, 'h1');
      const h1 = ReactDOM.findDOMNode(headline);
      return expect(h1.textContent).to.eq('No activity this week');
    });
  });

  describe('timeline is empty, edit permissions', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek
        empty_timeline
        edit_permissions
      />
    );
    it('suggests editing the week', () => {
      const pTag = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestEmptyWeek, 'p')[0];
      expect(makeSpacesUniform(pTag.textContent)).to.eq(
        makeSpacesUniform('To get started, start editing this week or start from a prebuilt assignment.')
      );
    });
  });

  describe('timeline is empty, no edit permissions', () => {
    const TestEmptyWeek = ReactTestUtils.renderIntoDocument(
      <EmptyWeek
        empty_timeline
      />
    );
    it('says course has no timeline', () => {
      const pTag = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestEmptyWeek, 'p')[0];
      expect(pTag.textContent).to.eq('This course has no timeline.');
    });
  });
});
