import deepFreeze from 'deep-freeze';
import '../testHelper';
import ui from '../../app/assets/javascripts/reducers/ui.js';
import * as actions from '../../app/assets/javascripts/actions';

describe('ui reducer', () => {
  test('handles initial state', () => {
    expect(ui(undefined, {})).toEqual({ openKey: null });
  });

  test('toggles to open', () => {
    expect(ui(undefined, actions.toggleUI('1234'))).toEqual({ openKey: '1234' });
  });

  test('toggles open key back to null', () => {
    const initialState = { openKey: '1234' };
    deepFreeze(initialState);

    expect(ui(initialState, actions.toggleUI('1234'))).toEqual({ openKey: null });
  });
});
