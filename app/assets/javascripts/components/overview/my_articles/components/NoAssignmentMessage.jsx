import React from 'react';

export default ({ course }) => {
  const evaluatingLink = course.type === 'FellowsCohort' ? '/training/professional-development/evaluating-articles-professional' : '/training/students/evaluating-articles';

  return (
    <div>
      <p>You have not chosen an article to work on. When you have found an article to work on, use the button above to assign it.</p>
      <aside>
        <a href="/training/students/keeping-track-of-your-work" target="_blank" className="button ghost-button">
          How to use the Dashboard
        </a>
        <a href="/training/students/finding-your-article" target="_blank" className="button ghost-button">
          How to find an article
        </a>
        <a href={evaluatingLink} target="_blank" className="button ghost-button">
          Evaluating articles and sources
        </a>
      </aside>
    </div>
  );
};
