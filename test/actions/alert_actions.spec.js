import '../testHelper';
import * as actions from 'actions/alert_actions';
import sinon from 'sinon';

describe('AlertActions', () => {
  const initialState = { submitting: false, created: false };
  const expectedState = { submitting: false, created: true };
  it('submits and creates an alert, then resets it', () => {
    expect(reduxStore.getState().needHelpAlert).to.deep.eq(initialState);
    sinon.stub($, "ajax").yieldsTo("success", { success: true });
    reduxStore.dispatch(actions.submitNeedHelpAlert({}))
      .then(() => {
        expect(reduxStore.getState().needHelpAlert).to.deep.eq(expectedState);
      })
      .then(() => {
        reduxStore.dispatch(actions.resetNeedHelpAlert());
        expect(reduxStore.getState().needHelpAlert).to.deep.eq(initialState);
      });
  });
});
