import { createStore, applyMiddleware, compose } from 'redux';
import reducer from '../../reducers';
import thunk from 'redux-thunk';

export const getStore = () => {
  const reactRoot = document.getElementById('react_root');
  if (!reactRoot) {
    return null;
  }
  const currentUserFromHtml = JSON.parse(reactRoot.getAttribute('data-current_user'));
  const admins = JSON.parse(reactRoot.getAttribute('data-admins'));

  // This is basic, minimal state info extracted from the HTML,
  // used for initial rendering before React fetches all the specific
  // data it needs via API calls.
  const preloadedState = {
    courseCreator: {
      defaultCourseType: reactRoot.getAttribute('data-default-course-type'),
      courseStringPrefix: reactRoot.getAttribute('data-course-string-prefix'),
      courseCreationNotice: reactRoot.getAttribute('data-course-creation-notice'),
      useStartAndEndTimes: reactRoot.getAttribute('data-use-start-and-end-times') === 'true'
    },
    currentUserFromHtml,
    admins
  };
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const store = createStore(
    reducer,
    preloadedState,
    composeEnhancers(applyMiddleware(thunk))
  );
  return store;
};

export default getStore();
