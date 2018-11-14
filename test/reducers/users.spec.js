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
    const initialState = users(undefined, { type: null });
    deepFreeze(initialState);

    const action = (type, users_array) => ({
      type: type,
      data: {
        course: {
          users: users_array
        }
      }
    });

    let users_array = [
      { id: 1, username: 'foo', role: 'student' },
      { id: 2, username: 'bar', role: 'admin' }
    ];
    const mockedReceivedAction = action(RECEIVE_USERS, users_array);
    const receiveUserState = users(initialState, mockedReceivedAction);
    expect(receiveUserState.users).to.deep.eq(users_array);
    expect(receiveUserState.isLoaded).to.eq(true);

    users_array = [
      { id: 1, username: 'foo', role: 'student' },
      { id: 2, username: 'bar', role: 'admin' },
      { id: 3, username: 'buzz', role: 'student' }
    ];
    const mockedAddAction = action(ADD_USER, users_array);
    const addUserState = users(receiveUserState, mockedAddAction);
    expect(addUserState.users).to.deep.eq(users_array);
    expect(addUserState.isLoaded).to.eq(true);

    users_array = [
      { id: 1, username: 'foo', role: 'student' },
      { id: 2, username: 'bar', role: 'admin' }
    ];
    const mockedRemoveAction = action(REMOVE_USER, users_array);
    const removeUserState = users(addUserState, mockedRemoveAction);
    expect(removeUserState.users).to.deep.eq(users_array);
    expect(removeUserState.isLoaded).to.eq(true);
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
