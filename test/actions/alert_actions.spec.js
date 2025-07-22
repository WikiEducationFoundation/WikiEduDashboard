import * as actions from 'actions/alert_actions';
import '../testHelper';

describe('AlertActions', () => {
  const initialState = { submitting: false, created: false };
  const expectedState = { submitting: false, created: true };
  const expectedNewState = { submitting: true, created: false };
  const messageData = {
    target_user_id: 2,
    message: 'new Message',
    course_id: 1
  };
  test('submits and creates an alert, then resets it', async () => {
    expect(reduxStore.getState().needHelpAlert).toEqual(initialState);
    sinon.stub($, 'ajax').yieldsTo('success', { success: true });
    await reduxStore.dispatch(actions.submitNeedHelpAlert({}));
    expect(reduxStore.getState().needHelpAlert).not.toEqual(expectedState);
    await reduxStore.dispatch(actions.submitNeedHelpAlert(messageData));
    expect(reduxStore.getState().needHelpAlert).toEqual(expectedNewState);
    reduxStore.dispatch(actions.resetNeedHelpAlert());
    expect(reduxStore.getState().needHelpAlert).toEqual(initialState);
  });
});
