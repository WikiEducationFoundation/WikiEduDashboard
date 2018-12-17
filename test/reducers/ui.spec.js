import deepFreeze from 'deep-freeze';
import '../testHelper';
import ui from '../../app/assets/javascripts/reducers/ui.js';
import * as actions from '../../app/assets/javascripts/actions';

describe('ui reducer', () => {
  it('handles initial state', () => {
    expect(ui(undefined, {})).to.deep.equal({ openKey: null });
  });

  it('toggles to open', () => {
    expect(ui(undefined, actions.toggleUI('1234'))).to.deep.equal({ openKey: '1234' });
  });

  it('toggles open key back to null', () => {
    const initialState = { openKey: '1234' };
    deepFreeze(initialState);

    expect(ui(initialState, actions.toggleUI('1234'))).to.deep.equal({ openKey: null });
  });
});
