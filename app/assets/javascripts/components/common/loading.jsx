import React from 'react';

const Loading = () => (
  <div className="loading">
    <h1>{I18n.t('courses.loading')}</h1>
    <div className="loading__spinner" />
  </div>
);

export default Loading;
