import React from 'react';
import OnClickOutside from 'react-onclickoutside';

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

  handleClickOutside() {
    this.hideDiff();
  },

  fetchDiff() {
    $.ajax(
      {
        dataType: 'jsonp',
        url: this.props.revision.api_url, // "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=139993&rvdiffto=prev",
        success: (data) => {
          const revisionData = data.query.pages[this.props.revision.mw_page_id].revisions[0];
          this.setState({
            diff: revisionData.diff['*'],
            comment: revisionData.comment,
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
      button = <button onClick={this.hideDiff} className="button dark small">Hide</button>;
    } else {
      style = 'hidden';
      button = <button onClick={this.showDiff} className="button dark small">Show</button>;
    }
    const className = `diff-viewer ${style}`;

    let diff;
    if (this.state.diff === '') {
      diff = '<div> — </div>';
    } else {
      diff = this.state.diff;
    }

    return (
      <div>
        {button}
        <div className={className}>
          <p>
            <a className="button dark small" href={this.props.revision.url} target="_blank">View on wiki</a>
            {button}
          </p>
          <table>
            <thead><p className="diff-comment">{this.state.comment}</p></thead>
            <tbody dangerouslySetInnerHTML={{ __html: diff }} />
          </table>
        </div>
      </div>
    );
  }
});

export default OnClickOutside(DiffViewer);
