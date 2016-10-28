import React from 'react';

const DiffViewer = React.createClass({
  displayName: 'DiffViweer',

  propTypes: {
    revision: React.PropTypes.object
  },

  getInitialState() {
    return { showDiff: false };
  },

  showDiff() {
    this.setState({ showDiff: true });
    if (!this.state.fetched) {
      this.fetchDiff();
    }
  },

  hideDiff() {
    this.setState({ showDiff: false });
  },

  fetchDiff() {
    console.log('ohai')
    $.ajax(
      {
        dataType: 'jsonp',
        url: "https://en.wikipedia.org/w/api.php?action=compare&fromrev=139992&torev=139993&format=json",
        success: (data) => { console.log(data); }
      });
  },

  render() {
    return (
      <div>
        <button onClick={this.fetchDiff} className="button dark">ohai</button>
        <a className="inline" href={this.props.revision.url} target="_blank">{I18n.t('revisions.diff')}</a>
      </div>
    );
  }
});

export default DiffViewer;
