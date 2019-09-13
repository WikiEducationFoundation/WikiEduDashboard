import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';

import '../../testHelper';
import configureMockStore from 'redux-mock-store';
import { MyAssignment } from '../../../app/assets/javascripts/components/overview/my_articles/my_assignment.jsx';
import Feedback from '../../../app/assets/javascripts/components/common/feedback.jsx';
import { MemoryRouter } from 'react-router';

const mockStore = configureMockStore([]);

describe('<MyAssignment />', () => {
  const store = mockStore({ feedback: {} });
  const assignment = {
    id: 1,
    role: 0,
    article_title: '1',
    article_url: 'https://en.wikipedia.org/wiki/1',
    assignment_all_statuses: ['status one', 'status two']
  };
  const course = { home_wiki: { language: 'en', project: 'wikipedia' } };

  it('feedback button is displayed on sandbox and improving articles', () => {
    const props = {
      assignment: assignment,
      course: course,
      current_user: { username: 'username' },
      last: false,
      wikidataLabels: {}
    };
    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter>
          <MyAssignment {...props} />
        </MemoryRouter>
      </Provider>
    );
    expect(wrapper.find(Feedback)).to.have.length(1);
  });

  it('feedback button not present for non English Wikipedia', () => {
    const props = {
      assignment: assignment,
      course: course,
      current_user: { username: 'username' },
      last: false,
      wikidataLabels: {}
    };
    props.course = { home_wiki: { language: 'en', project: 'wikivoyage' } };

    const wrapper = mount(
      <Provider store={store}>
        <MemoryRouter>
          <MyAssignment {...props} />
        </MemoryRouter>
      </Provider>
    );
    expect(wrapper.find(Feedback)).to.have.length(0);
  });
});
