// @ts-nocheck
import React from 'react';
import { mount } from 'enzyme';
import '../../../../../../../../../testHelper';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import MarkAsIncompleteButton from '../../../../../../../../../../app/assets/javascripts/components/overview/my_articles/components/Categories/List/Assignment/Header/Actions/MarkAsIncompleteButton';
import { Provider } from 'react-redux';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
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
  const update = jest.fn();
  const props = {
    assignment: { assignment_all_statuses: [] },
    courseSlug: 'course/slug',
  };
  it('should show the button', () => {
    const component = mount(<MockProvider {...props} />);
    expect(component).toMatchSnapshot();
  });

  it('should update the assignment on button click', async () => {
    const component = mount(<MockProvider {...props} />);
    const button = component.find('button');

    await button.props().onClick();
    expect(update.mock.calls.length).toEqual(1);
  });
});
