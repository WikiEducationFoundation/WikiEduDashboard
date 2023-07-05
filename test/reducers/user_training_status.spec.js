import '../testHelper';
import deepFreeze from 'deep-freeze';
import userTrainingStatus from '../../app/assets/javascripts/reducers/user_training_status';
import { RECEIVE_USER_TRAINING_STATUS } from '../../app/assets/javascripts/constants';

describe('user training status reducer', () => {
  test(
    'should return initial state when no action nor state is provided',
    () => {
      const newState = userTrainingStatus(undefined, { type: null });
      expect(Array.isArray(newState)).toBe(true);
    }
  );

  test('returns user training status with RECEIVE_USER_TRAINING_STATUS', () => {
    const initialState = [];
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_TRAINING_STATUS,
      data: { user: { training_modules: [{ id: 1 }, { id: 2 }] } }
    };

    const newState = userTrainingStatus(initialState, mockedAction);
    expect(newState).toEqual([{ id: 1 }, { id: 2 }]);
  });
});
