import React from 'react';
import PropTypes from 'prop-types';

export const BadWorkAlertButton = ({ showBadArticleAlert }) => (
  <button
    type="button"
    className="button small pull-right article-viewer-button"
    onClick={showBadArticleAlert}
  >
    {I18n.t('instructor_view.bad_work.quality_problems_button')}
  </button>
);

BadWorkAlertButton.propTypes = {
  showBadArticleAlert: PropTypes.func.isRequired
};

export default BadWorkAlertButton;
