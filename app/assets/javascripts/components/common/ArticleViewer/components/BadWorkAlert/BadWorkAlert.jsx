import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../../utils/article_utils';
// Components
import SubmitIssuePanel from '@components/common/ArticleViewer/components/BadWorkAlert/SubmitIssuePanel.jsx';

const BadWorkAlert = ({ project, submitBadWorkAlert }) => {
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (_key, messageText) => {
    setMessage(messageText);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    submitBadWorkAlert(message);
    setIsSubmitting(true);
  };

  return (
    <section className="article-alert">
      <article className="learn-more">
        <p>{I18n.t(`instructor_view.bad_work.${ArticleUtils.projectSuffix(project, 'learn_more')}`)}</p>
        <a target="_blank" className="button dark" href="/training/instructors/fixing-bad-articles/instructors-role-in-cleanup">
          {I18n.t('instructor_view.bad_work.learn_more_button')}
        </a>
      </article>
      <SubmitIssuePanel
        handleChange={handleChange}
        handleSubmit={handleSubmit}
        isSubmitting={isSubmitting}
        message={message}
        project={project}
      />
    </section>
  );
};

BadWorkAlert.propTypes = {
  project: PropTypes.string.isRequired,
  submitBadWorkAlert: PropTypes.func.isRequired
};

export default BadWorkAlert;
