import deepFreeze from 'deep-freeze';
import '../testHelper';
import reducer from '../../app/assets/javascripts/reducers/settings.js';
import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN, REVOKING_ADMIN } from '../../app/assets/javascripts/constants';

describe('Settings reducer', () => {
  test('should return the initial state', () => {
    const initialState = {
      adminUsers: [],
      specialUsers: {},
      fetchingUsers: false,
      submittingNewAdmin: false,
      submittingNewSpecialUser: false,
      revokingAdmin: {
        status: false,
        username: null,
      },
      revokingSpecialUser: {
        status: false,
        username: null,
      }
    };
    expect(reducer(undefined, {})).toEqual(initialState);
  });

  test('should update array with new admin users', () => {
    const oldAdmins = [{ id: 1, username: 'Admin1' }];
    const newAdmins = [{ id: 1, username: 'Admin1' }, { id: 2, username: 'Admin2' }];

    const initialState = {
      adminUsers: oldAdmins
    };
    deepFreeze(initialState);

    expect(
      reducer(initialState, {
        type: SET_ADMIN_USERS,
        data: { admins: newAdmins }
      })
    ).toEqual({
      adminUsers: newAdmins
    });
  });

  test('should update submitting new action', () => {
    const initialState = {
      submittingNewAdmin: false
    };
    deepFreeze(initialState);

    expect(
      reducer(initialState, {
        type: SUBMITTING_NEW_ADMIN,
        data: { submitting: true }
      })
    ).toEqual({
      submittingNewAdmin: true
    });
  });

  test('should update revokingAdmin', () => {
    const initialState = {
      revokingAdmin: {
        status: false,
        username: null,
      }
    };
    deepFreeze(initialState);

    expect(
      reducer(initialState, {
        type: REVOKING_ADMIN,
        data: {
          revoking: {
            status: true,
            username: 'bannedUser',
          }
        }
      })
    ).toEqual({
      revokingAdmin: {
        status: true,
        username: 'bannedUser',
      }
    });
  });
});
