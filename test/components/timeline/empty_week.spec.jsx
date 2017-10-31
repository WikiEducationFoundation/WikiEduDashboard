import '../../testHelper';

import React from 'react';
import EmptyWeek from '../../../app/assets/javascripts/components/timeline/empty_week.jsx';
import { mount } from 'enzyme';
const makeSpacesUniform = (str) => { return str.replace(/\s{1,}/g, ' '); };

describe('EmptyWeek', () => {
  const course = { slug: 'my_course', type: 'ClassroomProgramCourse' };

  describe('empty state', () => {
    const TestEmptyWeek = mount(
      <EmptyWeek />
    );
    it('gives the empty text if timeline and edit permissions are empty', () => {
      const headline = TestEmptyWeek.find('h1');
      expect(headline.text()).to.eq(I18n.t('timeline.no_activity_this_week'));
    });
  });

  describe('timeline is empty, edit permissions', () => {
    const TestEmptyWeek = mount(
      <EmptyWeek
        emptyTimeline
        edit_permissions
        course={course}
      />
    );
    it('suggests editing the week', () => {
      const pTag = TestEmptyWeek.find('.week__no-activity__get-started');
      expect(makeSpacesUniform(pTag.text())).to.eq(
        makeSpacesUniform('To get started, start editing this week or use the assignment wizard to create a timeline.')
      );
    });
  });

  describe('timeline is empty, no edit permissions', () => {
    const TestEmptyWeek = mount(
      <EmptyWeek
        emptyTimeline
      />
    );
    it('says course has no timeline', () => {
      const pTag = TestEmptyWeek.find('.week__no-activity__get-started');
      expect(makeSpacesUniform(pTag.text())).to.eq(
        makeSpacesUniform('This course has no timeline.')
      );
    });
  });
});
