import { TOGGLE_UI, RESET_UI, UPDATE_ARTICLES_CURRENT, TOGGLE_SCROLL_DEBOUNCE } from '../constants';

export const toggleUI = key => ({ type: TOGGLE_UI, key });
export const resetUI = key => ({ type: RESET_UI, key });

export const updateArticlesCurrent = (key) => {
  return {
    type: UPDATE_ARTICLES_CURRENT,
    key: key,
  };
};

// Toggle scroll debounce redux state so that on Navbar click
//  handle scroll function is not executed
export const toggleScrollDebounce = () => (dispatch) => {
  dispatch({
    type: TOGGLE_SCROLL_DEBOUNCE,
  });
  setTimeout(() => {
    dispatch({
      type: TOGGLE_SCROLL_DEBOUNCE,
    });
  }, 500);
};
