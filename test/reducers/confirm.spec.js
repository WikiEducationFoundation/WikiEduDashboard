import deepFreeze from 'deep-freeze';
import ui from '../../app/assets/javascripts/reducers/confirm';
import { CONFIRMATION_INITIATED, ACTION_CONFIRMED, ACTION_CANCELLED } from '../../app/assets/javascripts/constants';
import '../testHelper';

const initialState = {
    explanation: null,
    confirmationActive: false,
    confirmMessage: null,
    onConfirm: null,
    showInput: false,
    warningMessage: null,
  };

describe('article_details reducer', () => {
    test('should handle CONFIRMATION_INITIATED action by updating state', () => {
          const action = {
            type: CONFIRMATION_INITIATED,
            explanation: 'Test explanation',
            confirmationActive: true,
            confirmMessage: 'Test confirm message',
            onConfirm: jest.fn(),
            showInput: true,
            warningMessage: 'Test warning message',
          };

     const expectedState = {
    explanation: 'Test explanation',
    confirmationActive: true,
    confirmMessage: 'Test confirm message',
    onConfirm: expect.any(Function), // You can use expect.any(Function) for functions
    showInput: true,
    warningMessage: 'Test warning message',
  };
          deepFreeze(initialState);
          const newState = ui(initialState, action);

          expect(newState).toEqual(expectedState);
    });

  test('should handle ACTION_CONFIRMED action by resetting to initial state', () => {
    const action = {
      type: ACTION_CONFIRMED,
    };

    deepFreeze(initialState);
    const expectedState = initialState;
    const newState = ui(initialState, action);
    expect(newState).toEqual(ui(undefined, expectedState));
});

test('should handle ACTION_CANCELLED action by resetting to initial state', () => {
    const action = {
      type: ACTION_CANCELLED,
    };

    deepFreeze(initialState);
    const expectedState = initialState;
    const newState = ui(initialState, action);
    expect(newState).toEqual(ui(undefined, expectedState));
});
});
