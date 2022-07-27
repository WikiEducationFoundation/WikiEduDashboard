import React from 'react';
import { mount } from 'enzyme';

import { MemoryRouter } from 'react-router';

import '../../testHelper';
import EmptyWeek from '../../../app/assets/javascripts/components/timeline/empty_week.jsx';

const makeSpacesUniform = (str) => { return str.replace(/\s{1,}/g, ' '); };

describe('EmptyWeek', () => {
  const course = { slug: 'my_course', type: 'ClassroomProgramCourse' };

  describe('empty state', () => {
    const TestEmptyWeek = mount(
      <EmptyWeek
        addWeek={jest.fn()}
        timeline_start="2018-01-01"
        timeline_end="2018-01-31"
      />
    );
    it('gives the empty text if timeline and edit permissions are empty', () => {
      const headline = TestEmptyWeek.find('h1');
      expect(headline.text()).toEqual(I18n.t('timeline.no_activity_this_week'));
    });
  });

  describe('timeline is empty, edit permissions', () => {
    const TestEmptyWeek = mount(
      <MemoryRouter>
        <EmptyWeek
          emptyTimeline
          edit_permissions
          course={course}
          addWeek={jest.fn()}
          timeline_start="2018-01-01"
          timeline_end="2018-01-31"
        />
      </MemoryRouter>
    );
    it('suggests editing the week', () => {
      const pTag = TestEmptyWeek.find('.week__no-activity__get-started');
      expect(makeSpacesUniform(pTag.text())).toEqual(
        makeSpacesUniform('To get started, start editing this week or use the assignment wizard to create a timeline.')
      );
    });
  });

  describe('timeline is empty, no edit permissions', () => {
    const TestEmptyWeek = mount(
      <MemoryRouter>
        <EmptyWeek
          emptyTimeline
          addWeek={jest.fn()}
          timeline_start="2018-01-01"
          timeline_end="2018-01-31"
        />
      </MemoryRouter>
    );
    it('says course has no timeline', () => {
      const pTag = TestEmptyWeek.find('.week__no-activity__get-started');
      expect(makeSpacesUniform(pTag.text())).toEqual(
        makeSpacesUniform('This course has no timeline.')
      );
    });
  });
});
