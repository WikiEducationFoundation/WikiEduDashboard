import * as actions from 'actions/alert_actions';
import '../testHelper';

describe('AlertActions', () => {
  const initialState = { submitting: false, created: false };
  const expectedState = { submitting: false, created: true };
  test('submits and creates an alert, then resets it', () => {
    expect(reduxStore.getState().needHelpAlert).toEqual(initialState);
    sinon.stub($, 'ajax').yieldsTo('success', { success: true });
    reduxStore.dispatch(actions.submitNeedHelpAlert({}))
      .then(() => {
        expect(reduxStore.getState().needHelpAlert).toEqual(expectedState);
      })
      .then(() => {
        reduxStore.dispatch(actions.resetNeedHelpAlert());
        expect(reduxStore.getState().needHelpAlert).toEqual(initialState);
      });
  });
});
