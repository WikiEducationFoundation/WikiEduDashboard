import { configureStore } from '@reduxjs/toolkit';
import reducer from '../../reducers';

export const getStore = () => {
  const reactRoot = document.getElementById('react_root');
  const navRoot = document.getElementById('nav_root');

  if (!reactRoot && !navRoot) {
    return null;
  }

  let preloadedState;

  if (reactRoot) {
    const currentUserFromHtml = JSON.parse(reactRoot.getAttribute('data-current_user'));
    const admins = JSON.parse(reactRoot.getAttribute('data-admins'));
    // This is basic, minimal state info extracted from the HTML,
    // used for initial rendering before React fetches all the specific
    // data it needs via API calls.
    preloadedState = {
      courseCreator: {
        defaultCourseType: reactRoot.getAttribute('data-default-course-type'),
        courseStringPrefix: reactRoot.getAttribute('data-course-string-prefix'),
        courseCreationNotice: reactRoot.getAttribute('data-course-creation-notice'),
        useStartAndEndTimes: reactRoot.getAttribute('data-use-start-and-end-times') === 'true'
      },
      currentUserFromHtml,
      admins
    };
  }

  // Determine if mutation checks should be enabled
  const enableMutationChecks = false;

  const store = configureStore({
    reducer,
    preloadedState,
    middleware: getDefaultMiddleware =>
      getDefaultMiddleware({
      // Temporarily disable mutation checks feature to facilitate Redux Toolkit migration.
      // TODO: Gradually resolve state mutations and re-enable these checks in the future.
      // Enable mutation checks when resolving or detecting these issues by setting enableMutationChecks to true.
        immutableCheck: enableMutationChecks,
        serializableCheck: enableMutationChecks,
      }),
    // Enable Redux DevTools
    devTools: true
  });

  return store;
};

export default getStore();
