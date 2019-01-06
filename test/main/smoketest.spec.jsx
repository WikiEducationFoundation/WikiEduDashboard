import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import ReactTestUtils from 'react-dom/test-utils';
import '../testHelper';

import Course from '../../app/assets/javascripts/components/course/course.jsx';
import OverviewHandler from '../../app/assets/javascripts/components/overview/overview_handler.jsx';

describe('top-level course component', () => {
  document.body.innerHTML = "<div data-current_user='{ \"admin\": false, \"id\": null }' id='react_root'></div>";

  it('loads without an error', () => {
    const courseProps = {
      location: {
        query: { enroll: 'passcode' },
        pathname: '/courses/this_school/this_course'
      },
      params: { course_school: 'this_school', course_title: 'this_course' }
    };
    const currentUser = {
      role: 0,
      username: 'Ragesoss',
      admin: true
    };
    global.Features = { enableGetHelpButton: true };
    const testCourse = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStore}>
        <MemoryRouter>
          <Course {...courseProps}>
            <OverviewHandler {...courseProps} current_user={currentUser} />
          </Course>
        </MemoryRouter>
      </Provider>
    );
    expect(testCourse).to.exist;
  });
});
