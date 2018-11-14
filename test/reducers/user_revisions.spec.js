import deepFreeze from 'deep-freeze';
import '../testHelper';
import userRevisions from '../../app/assets/javascripts/reducers/user_revisions';
import { RECEIVE_USER_REVISIONS } from '../../app/assets/javascripts/constants';

describe('user revisions reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = userRevisions(undefined, { type: null });
    expect(newState).to.be.an('object');
  });

  it('receives user revisions data with user identification as key via RECEIVE_USER_REVISIONS', () => {
    const initialState = {};
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USER_REVISIONS,
      data: { course: { revisions: [] } },
      userId: 3
    };

    const firstState = userRevisions(initialState, mockedAction);
    expect(firstState[3]).to.be.an('array');
    expect(firstState[4]).to.eq(undefined);

    mockedAction.userId = 4;
    const secondState = userRevisions(firstState, mockedAction);
    expect(secondState[4]).to.be.an('array');
    expect(secondState[3]).to.be.an('array');
  });
});
