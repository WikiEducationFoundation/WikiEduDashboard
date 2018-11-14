import '../testHelper';
import deepFreeze from 'deep-freeze';
import userTrainingStatus from '../../app/assets/javascripts/reducers/user_training_status';
import { RECEIVE_USER_TRAINING_STATUS } from '../../app/assets/javascripts/constants';

describe('user training status reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = userTrainingStatus(undefined, { type: null });
    expect(newState).to.be.an('array');
  });

  it('returns user training status with RECEIVE_USER_TRAINING_STATUS', () => {
    const initialState = [];
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_TRAINING_STATUS,
      data: { user: { training_modules: [{ id: 1 }, { id: 2 }] } }
    };

    const newState = userTrainingStatus(initialState, mockedAction);
    expect(newState).to.deep.eq([{ id: 1 }, { id: 2 }]);
  });
});
