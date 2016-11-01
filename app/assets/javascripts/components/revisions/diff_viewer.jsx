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
    $.ajax(
      {
        dataType: 'jsonp',
        url: this.props.revision.api_url, // "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=139993&rvdiffto=prev",
        success: (data) => {
          this.setState({
            diff: data.query.pages[this.props.revision.mw_page_id].revisions[0].diff['*'],
            fetched: true
          });
        }
      });
  },

  render() {
    let style;
    let button;
    if (this.state.showDiff) {
      style = '';
      button = <button onClick={this.hideDiff} className="button dark">Hide diff</button>;
    } else {
      style = 'hidden';
      button = <button onClick={this.showDiff} className="button dark">Show diff</button>;
    }
    const className = `diff ${style}`;
    return (
      <div>
        {button}
        <div className={className}>
          <p><a className="inline" href={this.props.revision.url} target="_blank">{I18n.t('revisions.diff')}</a></p>
          <table><tbody dangerouslySetInnerHTML={{ __html: this.state.diff }} /></table>
        </div>
      </div>
    );
  }
});

export default DiffViewer;
