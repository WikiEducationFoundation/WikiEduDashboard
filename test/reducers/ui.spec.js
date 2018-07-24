import '../testHelper';
import ui from '../../app/assets/javascripts/reducers/ui.js';
import * as actions from '../../app/assets/javascripts/actions/ui_actions_redux.js';

describe('ui reducer', () => {
  it('handles initial state', () => {
    expect(ui(undefined, {})).to.deep.equal({ openKey: null, articles: { articlesCurrent: 'articles-edited', scrollDebounce: false } });
  });

  it('toggles to open', () => {
    expect(ui(undefined, actions.toggleUI('1234'))).to.deep.equal({ openKey: '1234', articles: { articlesCurrent: 'articles-edited', scrollDebounce: false } });
  });

  it('toggles open key back to null', () => {
    expect(ui({ openKey: '1234', articles: { articlesCurrent: 'articles-edited', scrollDebounce: false } }, actions.toggleUI('1234'))).to.deep.equal({ openKey: null, articles: { articlesCurrent: 'articles-edited', scrollDebounce: false } });
  });
});
