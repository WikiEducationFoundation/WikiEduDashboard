import React from 'react';
import OnClickOutside from 'react-onclickoutside';

const DiffViewer = React.createClass({
  displayName: 'DiffViweer',

  // Diff viewer takes a main (final) revision, and optionally a first revision.
  // If a first revision is supplied, it fetches a diff from the parent of the
  // first revision all the way to the main revision.
  propTypes: {
    revision: React.PropTypes.object.isRequired,
    first_revision: React.PropTypes.object,
    showButtonLabel: React.PropTypes.string,
    hideButtonLabel: React.PropTypes.string,
    largeButton: React.PropTypes.bool
  },

  getInitialState() {
    return {
      showDiff: false
    };
  },

  showButtonLabel() {
    if (this.props.showButtonLabel) {
      return this.props.showButtonLabel;
    }
    return I18n.t('revisions.diff_show');
  },

  hideButtonLabel() {
    if (this.props.hideButtonLabel) {
      return this.props.hideButtonLabel;
    }
    return I18n.t('revisions.diff_hide');
  },

  showDiff() {
    this.setState({ showDiff: true });
    if (!this.state.fetched) {
      this.initiateDiffFetch();
    }
  },

  hideDiff() {
    this.setState({ showDiff: false });
  },

  handleClickOutside() {
    this.hideDiff();
  },

  // If a first and current revision are provided, find the parent of the first revision
  // and get a diff from that parent to the current revision.
  // If only a current revision is provided, get diff to the previous revision.
  initiateDiffFetch() {
    if (this.props.first_revision) {
      return this.findParentOfFirstRevision();
    }

    this.fetchDiff(this.diffUrl());
  },

  wikiUrl() {
    return `https://${this.props.revision.wiki.language}.${this.props.revision.wiki.project}.org`;
  },

  diffUrl() {
    const wikiUrl = this.wikiUrl();
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions`;
    // eg, "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=139993&rvdiffto=prev&format=json",
    let diffUrl;
    if (this.state.parentRevisionId) {
      diffUrl = `${queryBase}&revids=${this.state.parentRevisionId}&rvdiffto=${this.props.revision.mw_rev_id}&format=json`;
    } else if (this.props.first_revision) {
      diffUrl = `${queryBase}&revids=${this.props.first_revision.mw_rev_id}&rvdiffto=${this.props.revision.mw_rev_id}&format=json`;
    } else {
      diffUrl = `${queryBase}&revids=${this.props.revision.mw_rev_id}&rvdiffto=prev&format=json`;
    }

    return diffUrl;
  },

  webDiffUrl() {
    if (this.state.parentRevisionId) {
      return `${this.wikiUrl()}/w/index.php?oldid=${this.state.parentRevisionId}&diff=${this.props.revision.mw_rev_id}`;
    } else if (this.props.first_revision) {
      return `${this.wikiUrl()}/w/index.php?oldid=${this.props.first_revision.mw_rev_id}&diff=${this.props.revision.mw_rev_id}`;
    }
    return `${this.wikiUrl()}/w/index.php?diff=${this.props.revision.mw_rev_id}`;
  },

  findParentOfFirstRevision() {
    const wikiUrl = `https://${this.props.first_revision.wiki.language}.${this.props.first_revision.wiki.project}.org`;
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions`;
    const diffUrl = `${queryBase}&revids=${this.props.first_revision.mw_rev_id}&format=json`;
    $.ajax(
      {
        dataType: 'jsonp',
        url: diffUrl,
        success: (data) => {
          const revisionData = data.query.pages[this.props.first_revision.mw_page_id].revisions[0];
          const parentRevisionId = revisionData.parentid;
          this.setState({ parentRevisionId });
          this.fetchDiff(this.diffUrl());
        }
      });
  },

  fetchDiff(diffUrl) {
    $.ajax(
      {
        dataType: 'jsonp',
        url: diffUrl,
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
    let button;
    let showButtonStyle;
    if (this.props.largeButton) {
      showButtonStyle = 'button dark';
    } else {
      showButtonStyle = 'button dark small';
    }

    if (this.state.showDiff) {
      button = <button onClick={this.hideDiff} className="button dark small">{this.hideButtonLabel()}</button>;
    } else {
      button = <button onClick={this.showDiff} className={showButtonStyle}>{this.showButtonLabel()}</button>;
    }

    let style = 'hidden';
    if (this.state.showDiff && this.state.fetched) {
      style = '';
    }
    const className = `diff-viewer ${style}`;

    let diff;
    if (this.state.diff === '') {
      diff = '<div> — </div>';
    } else {
      diff = this.state.diff;
    }

    const wikiDiffUrl = this.webDiffUrl();
    return (
      <div>
        {button}
        <div className={className}>
          <p>
            <a className="button dark small" href={wikiDiffUrl} target="_blank">{I18n.t('revisions.view_on_wiki')}</a>
            {button}
          </p>
          <table>
            <thead><tr><th colSpan="4" className="diff-header"><p className="diff-comment">{this.state.comment}</p></th></tr></thead>
            <tbody dangerouslySetInnerHTML={{ __html: diff }} />
          </table>
        </div>
      </div>
    );
  }
});

export default OnClickOutside(DiffViewer);
