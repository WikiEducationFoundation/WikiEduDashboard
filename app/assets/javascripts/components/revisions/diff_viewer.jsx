import React from 'react';

const DiffViewer = React.createClass({
  displayName: 'DiffViweer',

  propTypes: {
    revision: React.PropTypes.object
  },

  render() {
    return (
      <div>
        <a className="inline" href={this.props.revision.url} target="_blank">{I18n.t('revisions.diff')}</a>
      </div>
    );
  }
});

export default DiffViewer;
