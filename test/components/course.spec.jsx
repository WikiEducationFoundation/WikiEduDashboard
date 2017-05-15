import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import '../testHelper';
import Course from '../../app/assets/javascripts/components/course.jsx';

// Stub ServerActions methods. Otherwise, when run as a suite, ServerActions
// makes failing AJAX requests and tails the Notifications spec
import ServerActions from '../../app/assets/javascripts/actions/server_actions.js';

const storeStub = {
  getState: () => { return {}; },
  subscribe: () => { return; }
};

window.currentUser = { id: '', username: '' };
global.sinon.stub(ServerActions, 'fetch');

describe('Course', () => {
  const params = {
    course_school: 'test',
    course_title: 'test',
  };
  const location = {
    pathname: '/foo/bar/baz',
    query: ''
  };
  const TestCourse = ReactTestUtils.renderIntoDocument(
    <Course
      store={storeStub}
      params={params}
      location={location}
      children={<div></div>}
    />
  );

  // FIXME: This setState isn't working; the value of textContent is coupled
  // to the title set in course_actions.spec.js.
  global.beforeEach(() =>
    TestCourse.setState({
      course: {
        title: 'Test Course'
      }
    })
  );

  return it('renders the course title', () => {
    const title = ReactTestUtils.findRenderedDOMComponentWithTag(TestCourse, 'h2');
    return expect(title.textContent).to.eq('Test Course');
  });
});
