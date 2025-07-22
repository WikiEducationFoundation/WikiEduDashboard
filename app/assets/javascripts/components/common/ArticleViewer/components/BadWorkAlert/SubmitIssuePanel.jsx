import React from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../../../utils/article_utils';

// Components
import TextAreaInput from '@components/common/text_area_input.jsx';
import { useSelector } from 'react-redux';

export const SubmitIssuePanel = ({ handleChange, handleSubmit, isSubmitting, message, project }) => {
  const alertStatus = useSelector(state => state.badWorkAlert);
  if (alertStatus.created) {
    return (
      <article className="submit-alert">
        <p>{I18n.t('instructor_view.bad_work.thank_you')}</p>
      </article>
    );
  }

  return (
    <article className="submit-alert">
      <p>{I18n.t(`instructor_view.bad_work.${ArticleUtils.projectSuffix(project, 'submit_issue')}`)}</p>
      <form onSubmit={handleSubmit}>
        <TextAreaInput
          id="submit-bad-work-alert"
          editable
          name="message"
          onChange={handleChange}
          placeholder={I18n.t('instructor_view.bad_work.submit_issue_placeholder')}
          rows="2"
          value={message}
          value_key="message"
        />
        <button className="button danger" type="submit" disabled={isSubmitting}>
          Notify Wiki Expert
        </button>
      </form>
    </article>
  );
};

SubmitIssuePanel.propTypes = {
  handleChange: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  message: PropTypes.string.isRequired,
  project: PropTypes.string.isRequired
};

export default SubmitIssuePanel;
