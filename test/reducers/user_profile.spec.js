import '../testHelper';
import deepFreeze from 'deep-freeze';
import userProfile from '../../app/assets/javascripts/reducers/user_profile';
import { RECEIVE_USER_PROFILE_STATS } from '../../app/assets/javascripts/constants';

describe('user profile reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = userProfile(undefined, { type: null });
    expect(newState.stats).to.be.an('object');
    expect(newState.isLoading).to.eq(true);
  });

  it('receives stats from action and updates state attribute with RECEIVE_USER_PROFILE_STATS', () => {
    const initialState = { isLoading: true };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_PROFILE_STATS,
      data: {},
    };

    const newState = userProfile(initialState, mockedAction);
    expect(newState.isLoading).to.eq(false);
    expect(newState.stats).to.be.an('object');
  });
});
