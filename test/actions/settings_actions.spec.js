import '../testHelper';
import { fetchAdminUsers } from '../../app/assets/javascripts/actions/settings_actions';
import { SET_ADMIN_USERS, SUBMITTING_NEW_ADMIN, REVOKING_ADMIN } from "../../app/assets/javascripts/constants";

import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('SettingsAactions', () => {
  // example of how to test here: https://gist.github.com/kolodny/50e7384188bb5dc41ebb

  // or this: https://github.com/reactjs/redux/blob/master/docs/recipes/WritingTests.md#async-action-creators

  it('adds admin users to the store', () => {
    sinon.stub($, "ajax").yieldsTo("success", { spam: 'eggs' });
    const expectedActions = [
      { type: SET_ADMIN_USERS, data: { spam: 'eggs' } }
    ];

    const store = mockStore({ });
    return store.dispatch(fetchAdminUsers()).then(() => {
      expect(store.getActions()).to.eql(expectedActions);
    });
  });
});
