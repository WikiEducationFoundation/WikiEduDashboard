import deepFreeze from 'deep-freeze';
import '../testHelper';
import user_revisions from '../../app/assets/javascripts/reducers/user_revisions';
import { RECEIVE_USER_REVISIONS } from '../../app/assets/javascripts/constants';

describe('user revisions reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = user_revisions(undefined, { type: null });
    expect(newState).to.be.an('object');
  });

  it('receives user revisions data with user identification as key via RECEIVE_USER_REVISIONS', () => {
    const initialState = {
      title: 'title'
    };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_REVISIONS,
      data: { course: { revisions: true } },
      userId: 'username'
    };

    const newState = user_revisions(initialState, mockedAction);
    expect(newState.username).to.eq(true);
    expect(newState.title).to.eq('title');
  });
});
