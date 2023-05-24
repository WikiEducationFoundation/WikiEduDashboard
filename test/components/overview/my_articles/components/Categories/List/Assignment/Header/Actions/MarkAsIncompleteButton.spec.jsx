import React from 'react';
import { mount } from 'enzyme';
import '../../../../../../../../../testHelper';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { updateAssignmentStatus } from '../../../../../../../../../../app/assets/javascripts/actions/assignment_actions';
import MarkAsIncompleteButton from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/MarkAsIncompleteButton';
import { Provider } from 'react-redux';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
jest.mock('../../../../../../../../../../app/assets/javascripts/actions/assignment_actions', () => ({
  updateAssignmentStatus: jest.fn(),
}));
describe('MarkAsIncompleteButton', () => {
  const store = mockStore({
  });

  const MockProvider = (mockProps) => {
    return (
      <Provider store={store}>
        <MarkAsIncompleteButton {...mockProps} />
      </Provider >
    );
  };
  const props = {
    assignment: { assignment_all_statuses: [] },
    courseSlug: 'course/slug',
  };
  it('should show the button', () => {
    const component = mount(<MockProvider {...props} />);
    expect(component).toMatchSnapshot();
  });

  it('should update the assignment on button click', async () => {
    const newProps = {
      assignment: { assignment_all_statuses: ['status1', 'status2'] },
      courseSlug: 'course1',
    };

    const component = mount(<MockProvider {...newProps} />);
    component.find('button').simulate('click');

    expect(updateAssignmentStatus).toHaveBeenCalledWith(newProps.assignment, 'status1');
  });
});
