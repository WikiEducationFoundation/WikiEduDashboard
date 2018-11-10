import '../testHelper';
import deepFreeze from 'deep-freeze';
import user_profile from '../../app/assets/javascripts/reducers/user_profile';
import { RECEIVE_USER_PROFILE_STATS } from '../../app/assets/javascripts/constants';

describe('user profile reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = user_profile(undefined, { type: null });
    expect(newState.stats).to.an('object');
    expect(newState.isLoading).to.eq(true);
  });

  it('receives stats from action and updates state attribute with RECEIVE_USER_PROFILE_STATS', () => {
    const initialState = { title: 'title' };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_PROFILE_STATS,
      data: {},
      isLoading: true
    };

    const newState = user_profile(initialState, mockedAction);
    expect(newState.isLoading).to.eq(false);
    expect(newState.stats).to.be.an('object');
  });
});
