import React from 'react';

export default ({ course }) => {
<<<<<<< HEAD
  const findingLink = course.type === 'FellowsCohort'
      ? '/training/professional-development/finding-your-article-professional'
      : '/training/students/finding-your-article';
  const evaluatingLink = course.type === 'FellowsCohort'
      ? '/training/professional-development/evaluating-articles-professional'
      : '/training/students/evaluating-articles';

  return (
    <div>
      <p>{I18n.t('articles.not_choosen_article')}</p>
      <aside>
        <a
          href="/training/students/keeping-track-of-your-work"
          target="_blank"
          className="button ghost-button"
        >
          {I18n.t('articles.use_dashboard')}
        </a>
        <a href={findingLink} target="_blank" className="button ghost-button">
          {I18n.t('articles.how_to_find')}
        </a>
        <a
          href={evaluatingLink}
          target="_blank"
          className="button ghost-button"
        >
          {I18n.t('articles.evaluate_and_source')}
=======
  const findingLink = course.type === 'FellowsCohort' ? '/training/professional-development/finding-your-article-professional' : '/training/students/finding-your-article';
  const evaluatingLink = course.type === 'FellowsCohort' ? '/training/professional-development/evaluating-articles-professional' : '/training/students/evaluating-articles';

  return (
    <div>
      <p>You have not chosen an article to work on. When you have found an article to work on, use the button above to assign it.</p>
      <aside>
        <a href="/training/students/keeping-track-of-your-work" target="_blank" className="button ghost-button">
          How to use the Dashboard
        </a>
        <a href={findingLink} target="_blank" className="button ghost-button">
          How to find an article
        </a>
        <a href={evaluatingLink} target="_blank" className="button ghost-button">
          Evaluating articles and sources
>>>>>>> f3815a4f0 (Done)
        </a>
      </aside>
    </div>
  );
};
