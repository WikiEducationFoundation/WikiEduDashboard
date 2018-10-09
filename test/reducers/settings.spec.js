import '../testHelper';
import reducer from '../../app/assets/javascripts/reducers/settings.js';
import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN, REVOKING_ADMIN } from '../../app/assets/javascripts/constants';

describe('Settings reducer', () => {
  it('should return the initial state', () => {
    const initialState = {
      adminUsers: [],
      fetchingUsers: false,
      submittingNewAdmin: false,
      revokingAdmin: {
        status: false,
        username: null,
      }
    };
    expect(reducer(undefined, {})).to.deep.eq(initialState);
  });

  it('should update array with new admin users', () => {
    const oldAdmins = [{ id: 1, username: 'Admin1' }];
    const newAdmins = [{ id: 1, username: 'Admin1' }, { id: 2, username: 'Admin2' }];

    const initialState = {
      adminUsers: oldAdmins
    };
    expect(
      reducer(initialState, {
        type: SET_ADMIN_USERS,
        data: { admins: newAdmins }
      })
    ).to.deep.eq({
      adminUsers: newAdmins
    });
  });

  it('should update submitting new action', () => {
    const initialState = {
      submittingNewAdmin: false
    };
    expect(
      reducer(initialState, {
        type: SUBMITTING_NEW_ADMIN,
        data: { submitting: true }
      })
    ).to.deep.eq({
      submittingNewAdmin: true
    });
  });

  it('should update revokingAdmin', () => {
    const initialState = {
      revokingAdmin: {
        status: false,
        username: null,
      }
    };
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
    ).to.deep.eq({
      revokingAdmin: {
        status: true,
        username: 'bannedUser',
      }
    });
  });
});
