import React from 'react';
import { mount } from 'enzyme';
import { MemoryRouter, Route } from 'react-router-dom';
import '../testHelper';

import { Course } from '../../app/assets/javascripts/components/course/course.jsx';

describe('top-level course component', () => {
  it('loads without an error', () => {
    global.Features = { enableGetHelpButton: true };
    const course = {
      title: 'this_course',
      description: '',
      school: 'this_school'
    };
    const user = {
      role: 0,
      username: 'Ragesoss',
      admin: true
    };
    const props = {
      course, current_user: user
    };
    const fns = {
      fetchCourse: sinon.stub(),
      fetchUsers: sinon.stub(),
      fetchTimeline: sinon.stub(),
      fetchCampaigns: sinon.stub(),
      persistCourse: sinon.stub(),
      updateCourse: sinon.stub()
    };
    const testCourse = mount(
      <MemoryRouter initialEntries={['/courses/this_school/this_course']}>
        <Route
          exact
          path="/courses/:course_school/:course_title"
          render={location => (
            <Course
              {...location}
              {...props}
              {...fns}
            />
          )}
        />
      </MemoryRouter>
    );
    expect(testCourse).toExist;
  });
});
