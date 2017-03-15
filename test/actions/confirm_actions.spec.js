import '../testHelper';
import ConfirmActions from '../../app/assets/javascripts/actions/confirm_actions.js';
import ConfirmationStore from '../../app/assets/javascripts/stores/confirmation_store.js';

describe('ConfirmActions', () => {
  it('.confirmationInitiated sets the confirmation state to active', (done) => {
    expect(ConfirmationStore.isConfirmationActive()).to.eq(false);
    ConfirmActions.confirmationInitiated().then(() => {
      expect(ConfirmationStore.isConfirmationActive()).to.eq(true);
      done();
    });
  });

  it('.actionConfirmed sets the confirmation state to inactive', (done) => {
    expect(ConfirmationStore.isConfirmationActive()).to.eq(true);
    ConfirmActions.actionConfirmed().then(() => {
      expect(ConfirmationStore.isConfirmationActive()).to.eq(false);
      done();
    });
  });

  it('.actionCancelled sets the confirmation state to inactive', (done) => {
    ConfirmActions.confirmationInitiated()
    .then(() => { expect(ConfirmationStore.isConfirmationActive()).to.eq(true); })
    .then(() => { ConfirmActions.actionCancelled(); })
    .then(() => {
      expect(ConfirmationStore.isConfirmationActive()).to.eq(false);
      done();
    });
  });
});
