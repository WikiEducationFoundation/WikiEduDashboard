import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import jQuery from 'jquery';

import '../testHelper';
import { REVOKING_ADMIN, SET_ADMIN_USERS } from '../../app/assets/javascripts/constants';
import { downgradeAdmin, fetchAdminUsers, upgradeAdmin } from '../../app/assets/javascripts/actions/settings_actions';


const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SettingsActions', () => {
  // example of how to test here: https://gist.github.com/kolodny/50e7384188bb5dc41ebb

  // or this: https://github.com/reactjs/redux/blob/master/docs/recipes/WritingTests.md#async-action-creators

  beforeEach(() => {
    sinon.stub(jQuery, 'ajax').yieldsTo('success', { spam: 'eggs' });
  });

  afterEach(() => {
    jQuery.ajax.restore();
  });

  it('dispatches to SET_ADMIN_USERS', () => {
    const expectedActions = [
      { type: SET_ADMIN_USERS, data: { spam: 'eggs' } }
    ];

    const store = mockStore({ });
    return store.dispatch(fetchAdminUsers()).then(() => {
      expect(store.getActions()).to.eql(expectedActions);
    });
  });
});

describe('upgradeAdmin', () => {
  let cannedResponse;
  beforeEach(() => {
    cannedResponse = { spam: 'eggs' };
    sinon.stub(jQuery, 'ajax')
      .onCall(0).yieldsTo('success', {})
      .onCall(1).yieldsTo('success', { spam: 'eggs' });
  });

  afterEach(() => {
    jQuery.ajax.restore();
  });

  it('dispatches to SUBMITTING_NEW_ADMIN', () => {
    const username = 'someuser';
    const expectedActions = [
      {
        type: 'SUBMITTING_NEW_ADMIN',
        data: {
          submitting: true,
        },
      },
      {
        type: 'SUBMITTING_NEW_ADMIN',
        data: {
          submitting: false
        },
      },
      {
        type: 'ADD_NOTIFICATION',
        notification: {
          type: 'success',
          message: `${username} was upgraded to administrator.`,
          closable: true
        },
      },
      {
        type: 'SET_ADMIN_USERS',
        data: cannedResponse,
      }
    ];
    const store = mockStore({});
    return store.dispatch(upgradeAdmin(username)).then(() => {
      expect(store.getActions()).to.eql(expectedActions);
    });
  });
});

describe('downgradeAdmin', () => {
  let cannedResponse;
  beforeEach(() => {
    cannedResponse = { spam: 'eggs' };
    sinon.stub(jQuery, 'ajax')
      .onCall(0).yieldsTo('success', {})
      .onCall(1).yieldsTo('success', { spam: 'eggs' });
  });

  afterEach(() => {
    jQuery.ajax.restore();
  });

  it('dispatches correctly', () => {
    const username = 'someuser';
    const expectedActions = [
      {
        type: 'REVOKING_ADMIN',
        data: {
          revoking: {
            status: true,
            username: username,
          },
        },
      },
      {
        type: 'ADD_NOTIFICATION',
        notification: {
          type: 'success',
          message: `${username} was removed as an administrator.`,
          closable: true
        },
      },
      {
        type: 'SET_ADMIN_USERS',
        data: cannedResponse,
      },
      {
        type: REVOKING_ADMIN,
        data: {
          revoking: {
            status: false,
            username: username,
          },
        },
      }
    ];
    const store = mockStore({});
    return store.dispatch(downgradeAdmin(username)).then(() => {
      expect(store.getActions()).to.eql(expectedActions);
    });
  });
});
