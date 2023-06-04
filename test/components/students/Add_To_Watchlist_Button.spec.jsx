import React from 'react';
import { shallow } from 'enzyme';
import { useDispatch } from 'react-redux';
import AddToWatchlistButton from '../../../app/assets/javascripts/components/students/components/AddToWatchlistButton';
import { initiateConfirm } from '../../../app/assets/javascripts/actions/confirm_actions';
import '../../testHelper';

// Mocking the necessary dependencies
jest.mock('react-redux', () => ({
  useDispatch: jest.fn(),
}));

// Mocking the initiateConfirm action
jest.mock('../../../app/assets/javascripts/actions/confirm_actions.js', () => ({
  initiateConfirm: jest.fn(),
}));

describe('AddToWatchlistButton', () => {
  let wrapper;
  let dispatchMock;

  beforeEach(() => {
    dispatchMock = jest.fn();
    useDispatch.mockReturnValue(dispatchMock);

    wrapper = shallow(<AddToWatchlistButton slug="course-slug" />);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

   it('should dispatch initiateConfirm action on button click', () => {
    // Simulate the button click
    wrapper.find('.watchlist-button').simulate('click');

    // Assert that the initiateConfirm action was dispatched with the correct arguments
    expect(dispatchMock).toHaveBeenCalledTimes(1);
    expect(initiateConfirm).toHaveBeenCalledWith({
      confirmMessage: (I18n.t('users.sub_navigation.watch_list.instructional_message')),
      onConfirm: expect.any(Function),
    });
  });


  it('should render the tooltip message', () => {
    const tooltip = wrapper.find('.tooltip');
    expect(tooltip.text()).toBe(I18n.t('users.sub_navigation.watch_list.tooltip_message'));
  });
});

