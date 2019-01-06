import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { MemoryRouter } from 'react-router-dom';
import history from '../../../app/assets/javascripts/components/util/history';

import '../../testHelper';
import MyArticles from '../../../app/assets/javascripts/components/overview/my_articles.jsx';

describe('MyArticles', () => {
  const course = {};
  const currentUser = { id: 1, admin: false, role: 0 };
  const courseId = 'institution/title_(term)';

  MyArticles.__Rewire__(
    'AssignCell',
    () => <div />
  );

  it('renders the My Articles header', () => {
    const TestMyArticles = ReactTestUtils.renderIntoDocument(
      <MemoryRouter history={history}>
        <MyArticles
          store={reduxStore}
          course={course}
          course_id={courseId}
          current_user={currentUser}
        />
      </MemoryRouter>
    );
    const module = ReactTestUtils.findRenderedDOMComponentWithTag(TestMyArticles, 'h3');
    expect(module.textContent).to.eq('My Articles');
  });
});
