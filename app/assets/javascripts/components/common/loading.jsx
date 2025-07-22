import React from 'react';

const Loading = ({ text }) => (
  <div className="loading">
    <h1>{text || I18n.t('courses.loading')}</h1>
    <div className="loading__spinner" />
  </div>
);

export default Loading;
