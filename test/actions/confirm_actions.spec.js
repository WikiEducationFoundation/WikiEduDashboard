import '../testHelper';
import { confirmationInitiated, actionConfirmed, actionCancelled } from '../../app/assets/javascripts/actions/confirm_actions.js';
import Confirmation from '../../app/assets/javascripts/reducers/confirmation.js';

describe('ConfirmActions', () => {
  it('.confirmationInitiated sets the confirmation state to active', (done) => {
    expect(Confirmation._confirmationActive).to.eq(false);
    confirmationInitiated().then(() => {
      expect(Confirmation._confirmationActive).to.eq(true);
      done();
    });
  });

  it('.actionConfirmed sets the confirmation state to inactive', (done) => {
    expect(Confirmation._confirmationActive).to.eq(true);
    actionConfirmed().then(() => {
      expect(Confirmation._confirmationActive).to.eq(false);
      done();
    });
  });

  it('.actionCancelled sets the confirmation state to inactive', (done) => {
    confirmationInitiated()
    .then(() => { expect(Confirmation._confirmationActive).to.eq(true); })
    .then(() => { actionCancelled(); })
    .then(() => {
      expect(Confirmation._confirmationActive).to.eq(false);
      done();
    });
  });
});
