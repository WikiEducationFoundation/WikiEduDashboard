import { createBrowserHistory } from 'history';

// Custom history component handles scroll position for back button, hashes,
// and normal links
const browserHistory = createBrowserHistory();
browserHistory.listen((location) => {
  setTimeout(() => {
    if (location.action === 'POP') {
      return;
    }
    const hash = window.location.hash;
    if (hash) {
      const element = document.getElementById(hash);
      if (element) {
        element.scrollIntoView({
          block: 'start',
          behavior: 'smooth'
        });
      }
    } else {
      window.scrollTo(0, 0);
    }
  });
});

export default browserHistory;
