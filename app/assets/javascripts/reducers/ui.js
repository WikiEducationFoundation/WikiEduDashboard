import { TOGGLE_UI, RESET_UI, UPDATE_ARTICLES_CURRENT, TOGGLE_SCROLL_DEBOUNCE } from '../constants';

const initialState = {
  openKey: null,
  articles: {
    articlesCurrent: 'articles-edited',
    scrollDebounce: false,
  },
};

export default function ui(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_UI:
      if (action.key === state.openKey) {
        return { ...state, openKey: null };
      }
      return { ...state, openKey: action.key };
    case RESET_UI:
      return { ...state, openKey: null };
    case UPDATE_ARTICLES_CURRENT:
      return { ...state, articles: { ...state.articles, articlesCurrent: action.key } };
    case TOGGLE_SCROLL_DEBOUNCE:
      return { ...state, articles: { ...state.articles, scrollDebounce: !state.articles.scrollDebounce } };
    default:
      return state;
  }
}
