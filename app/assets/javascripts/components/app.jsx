import React from 'react';
import Nav from './nav/nav.jsx';
import SerifModeToggle from './nav/serif_mode_toggle.jsx';
import { render as renderMain } from './Main';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import store from './util/create_store';
import ClaimVerificationViewer from './common/ArticleViewer/containers/ClaimVerificationViewer.jsx';

// The navbar is its own React element, independent of the
// main React Router-based component tree.
// `nav_root` is present throughout the app, via the Rails view layouts.
const navBar = document.getElementById('nav_root');

if (navBar) {
  const navRoot = createRoot(navBar); // createRoot(container!) if you use TypeScript
  // Render the Nav component with Redux store
  navRoot.render(
    <Provider store={store}>
      <Nav />
    </Provider>
  );
}

const fontToggle = document.getElementById('font_toggle_root');
if (fontToggle) {
  createRoot(fontToggle).render(<SerifModeToggle />);
}

const reactRoot = document.getElementById('react_root');

if (reactRoot) {
  // Render the Main component with the same Redux store and React Router
  renderMain(
    reactRoot,
    store
  );
}

// The claim-verification exercise is a server-rendered page that mounts the
// ArticleViewer (claim-highlighting variant) as its main content. Its article
// and course come from data attributes on the mount node.
const claimViewer = document.getElementById('claim-verification-viewer');
if (claimViewer) {
  const { dataset } = claimViewer;
  const article = {
    id: Number(dataset.articleId),
    title: dataset.articleTitle,
    language: dataset.articleLanguage,
    project: dataset.articleProject,
    url: dataset.articleUrl,
    mw_page_id: Number(dataset.articleMwPageId),
  };
  const course = { id: Number(dataset.courseId), slug: dataset.courseSlug };
  createRoot(claimViewer).render(
    <Provider store={store}>
      <ClaimVerificationViewer article={article} course={course} />
    </Provider>
  );
}
