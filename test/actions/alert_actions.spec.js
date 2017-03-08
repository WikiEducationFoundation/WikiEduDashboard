import '../testHelper';
import AlertActions from '../../app/assets/javascripts/actions/alert_actions.js';
import AlertsStore from '../../app/assets/javascripts/stores/alerts_store.js';

import sinon from 'sinon';

describe('AlertActions', () => {
  beforeEach(() => {
    sinon.stub($, 'ajax').yieldsTo('success', { success: true });
  });
  afterEach(() => {
    $.ajax.restore();
  });

  it('makes an ajax call for submitNeedHelpAlert', () => {
    AlertActions.submitNeedHelpAlert({}).then(() => {
      expect(AlertsStore.getNeedHelpAlertSubmitted()).to.be.true;
    });
    expect($.ajax.calledOnce).to.be.true;
    AlertActions.resetNeedHelpAlert().then(() => {
      expect(AlertsStore.getNeedHelpAlertSubmitted()).to.be.false;
    });
  });
});
