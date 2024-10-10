import React from 'react';

export default ({ course }) => {
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
        </a>
      </aside>
    </div>
  );
};
