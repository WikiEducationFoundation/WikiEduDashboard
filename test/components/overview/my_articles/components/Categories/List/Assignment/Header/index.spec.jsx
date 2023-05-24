import React from 'react';
import { mount } from 'enzyme';
import '../../../../../../../../testHelper';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

import Header from '@components/overview/my_articles/components/Categories/List/Assignment/Header/Header.jsx';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
describe('Header', () => {
  const store = mockStore({
  });

  const MockProvider = (mockProps) => {
    return (
      <Provider store={store}>
        <Header {...mockProps} />
      </Provider >
    );
  };
  const props = {
    article: {
      project: 'project'
    },
    articleTitle: 'title',
    assignment: {},
    course: { slug: 'course/slug', type: 'ClassroomProgramCourse' },
    current_user: {},
    isComplete: true,
    username: 'username',
    deleteAssignment: jest.fn(),
    fetchAssignments: jest.fn(),
    initiateConfirm: jest.fn(),
    updateAssignmentStatus: jest.fn()
  };

  it('displays the links and actions', () => {
    const component = mount(<MockProvider {...props} />);
    expect(component).toMatchSnapshot();
  });
});
