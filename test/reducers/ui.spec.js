import '../testHelper';
import ui from '../../app/assets/javascripts/reducers/ui.js';
import * as types from '../../app/assets/javascripts/constants/action_types.js';

describe('ui reducer', () => {
  it('handles initial state', () => {
    expect(ui(undefined, {})).to.deep.equal({ openKey: null });
  });

  it('toggles to open', () => {
    expect(ui(undefined, { type: types.TOGGLE_UI, key: '1234' })).to.deep.equal({ openKey: '1234' });
  });

  it('toggles open key back to null', () => {
    expect(ui({ openKey: '1234' }, { type: types.TOGGLE_UI, key: '1234' })).to.deep.equal({ openKey: null });
  });
});
