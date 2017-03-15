import '../testHelper';
import AlertActions from '../../app/assets/javascripts/actions/alert_actions.js';
import AlertsStore from '../../app/assets/javascripts/stores/alerts_store.js';

import sinon from 'sinon';

describe('AlertActions', () => {
  beforeEach(() => {
    sinon.stub($, "ajax").yieldsTo("success", { success: true });
  });
  afterEach(() => {
    $.ajax.restore();
    AlertActions.resetNeedHelpAlert();
  });

  it('.submitNeedHelpAlert sets getNeedHelpAlertSubmitting to true', (done) => {
    AlertActions.submitNeedHelpAlert({}).then(() => {
      expect(AlertsStore.getNeedHelpAlertSubmitting()).to.be.true;
      done();
    });
  });

  it('.createNeedHelpAlert sets getNeedHelpAlertSubmitted to true', (done) => {
    AlertActions.createNeedHelpAlert({}).then(() => {
      expect(AlertsStore.getNeedHelpAlertSubmitted()).to.be.true;
      done();
    });
  });
});
