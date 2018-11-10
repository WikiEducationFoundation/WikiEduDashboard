import '../testHelper';
import deepFreeze from 'deep-freeze';
import user_training_status from '../../app/assets/javascripts/reducers/user_training_status';
import { RECEIVE_USER_TRAINING_STATUS } from '../../app/assets/javascripts/constants';

describe('user training status reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = user_training_status(undefined, { type: null });
    expect(newState).to.be.an('object');
  });

  it('returns user training status with RECEIVE_USER_TRAINING_STATUS', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_TRAINING_STATUS,
      data: { user: { training_modules: { key: 'value' } } }
    };

    const newState = user_training_status(initialState, mockedAction);
    expect(newState).to.deep.eq({ key: 'value' });
  });
});
