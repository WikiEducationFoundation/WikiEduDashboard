import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import fetch from 'cross-fetch';
import { fetchOnboardingAlert } from '../../app/assets/javascripts/actions/course_alert_actions';
import * as types from '../../app/assets/javascripts/constants';
import '../testHelper';

jest.mock('cross-fetch');

describe('CourseAlertsActions', () => {
  let store;
  beforeEach(() => {
    const mockStore = configureMockStore([thunk]);
    store = mockStore({});
  });
  describe('#fetchOnboardingAlert', () => {
    it('dispatches a message upon a successful alert request', async () => {
      fetch.mockResolvedValue(Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({})
      }));

      await store.dispatch(fetchOnboardingAlert({ id: 1 }));
      const actions = store.getActions();
      expect(actions.length).to.equal(1);

      const [action] = actions;
      expect(action.type).to.equal(types.RECEIVE_ONBOARDING_ALERT);
    });
    it('dispatches a failure if the api request is unsuccessful', async () => {
      fetch.mockResolvedValue(Promise.resolve({
        ok: false,
        status: 500
      }));

      await store.dispatch(fetchOnboardingAlert({ id: 1 }));
      const actions = store.getActions();
      expect(actions.length).to.equal(1);

      const [action] = actions;
      expect(action.type).to.equal(types.API_FAIL);
    });
  });
});
