import React from 'react';
import createReactClass from 'create-react-class';

const Loading = createReactClass({
  displayName: 'Loading',

  render() {
    return (
      <div className="loading">
        <h1>{I18n.t('courses.loading')}</h1>
        <div className="loading__spinner" />
      </div>
    );
  }
});

export default Loading;
