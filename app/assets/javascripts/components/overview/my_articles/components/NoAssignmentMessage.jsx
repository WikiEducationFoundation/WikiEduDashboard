import React from 'react';

export default () => (
  <section className="no-assignment-message">
    <p>You have not chosen an article to work on. Please use the buttons below to assign yourself an article.</p>
    <aside>
      <a href="/training/students/finding-your-article" target="_blank" className="button ghost-button">
        How to find an article
      </a>
      <a href="/training/students/evaluating-articles" target="_blank" className="button ghost-button">
        Evaluating articles and sources
      </a>
    </aside>
  </section>
);
