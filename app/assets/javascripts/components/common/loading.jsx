import React from 'react';
import PropTypes from 'prop-types';

const Loading = ({ text }) => (
  <div className="loading" aria-live="polite">
    <h1>{text || I18n.t('courses.loading')}</h1>
    <div className="loading__spinner" />
  </div>
);

Loading.propTypes = {
  text: PropTypes.string
};

export default Loading;
