import deepFreeze from 'deep-freeze';
import users from '../../app/assets/javascripts/reducers/users';
import '../testHelper';
import {
  RECEIVE_USERS,
  ADD_USER,
  REMOVE_USER,
  SORT_USERS
} from '../../app/assets/javascripts/constants';

describe('users reducer', () => {
  it('should return initial state when no action nor state is provided', () => {
    const newState = users(undefined, { type: null });
    expect(newState.users).to.be.an('array');
    expect(newState.isLoaded).to.eq(false);
    expect(newState.sort).to.be.an('object');
  });

  it('returns the previous state and updates users array from action via RECEIVE_USERS, ADD_USER and REMOVE_USER', () => {
    const initialState = { title: 'title', isLoaded: false };
    deepFreeze(initialState);
    const mockedAction = {
      type: RECEIVE_USERS,
      data: { course: { users: [1, 2] } }
    };

    let newState = users(initialState, mockedAction);
    expect(newState.title).to.eq('title');
    expect(newState.users).to.deep.eq([1, 2]);
    expect(newState.isLoaded).to.eq(true);

    mockedAction.type = ADD_USER;
    mockedAction.data.course.users = [1, 2, 3];
    newState = users(initialState, mockedAction);
    expect(newState.users).to.deep.eq([1, 2, 3]);

    mockedAction.type = REMOVE_USER;
    mockedAction.data.course.users = [1, 2];
    newState = users(initialState, mockedAction);
    expect(newState.users).to.deep.eq([1, 2]);
  });

  it('sorts users given a key by action via SORT_USERS', () => {
    const initialState = {
      title: 'title',
      isLoaded: false,
      users: [
        { id: 2, name: 'user3' },
        { id: 3, name: 'user2' },
        { id: 1, name: 'user1' }
      ],
      sort: {
        sortKey: null
      }
    };
    deepFreeze(initialState);
    const mockedAction = {
      type: SORT_USERS,
      key: 'id'
    };

    let newState = users(initialState, mockedAction);
    expect(newState.users).to.deep.eq([
      { id: 1, name: 'user1' },
      { id: 2, name: 'user3' },
      { id: 3, name: 'user2' }
    ]);

    mockedAction.key = 'name';
    newState = users(initialState, mockedAction);
    expect(newState.users).to.deep.eq([
      { id: 1, name: 'user1' },
      { id: 3, name: 'user2' },
      { id: 2, name: 'user3' }
    ]);

    expect(newState.title).to.eq('title');
  });
});
