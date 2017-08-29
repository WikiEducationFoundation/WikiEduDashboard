import React from 'react';
import OnClickOutside from 'react-onclickoutside';
import SalesforceMediaButtons from '../articles/salesforce_media_buttons.jsx';

const DiffViewer = React.createClass({
  displayName: 'DiffViewer',

  // Diff viewer takes a main (final) revision, and optionally a first revision.
  // If a first revision is supplied, it fetches a diff from the parent of the
  // first revision all the way to the main revision.
  // If there is no parent of the first revision — typically because it's the start
  // of a new article — then it uses the first revision as the starting point.
  propTypes: {
    revision: React.PropTypes.object.isRequired,
    first_revision: React.PropTypes.object,
    showButtonLabel: React.PropTypes.string,
    largeButton: React.PropTypes.bool,
    editors: React.PropTypes.array,
    showSalesforceButton: React.PropTypes.bool,
    article: React.PropTypes.object,
    course: React.PropTypes.object
  },

  getInitialState() {
    return {
      showDiff: false,
    };
  },

  showButtonLabel() {
    if (this.props.showButtonLabel) {
      return this.props.showButtonLabel;
    }
    return I18n.t('revisions.diff_show');
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
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions&rvprop=ids|timestamp|comment`;
    // eg, "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=139993&rvdiffto=prev&format=json",
    let diffUrl;
    if (this.state.parentRevisionId) {
      diffUrl = `${queryBase}&revids=${this.state.parentRevisionId}|${this.props.revision.mw_rev_id}&rvdiffto=${this.props.revision.mw_rev_id}&format=json`;
    } else if (this.props.first_revision) {
      diffUrl = `${queryBase}&revids=${this.props.first_revision.mw_rev_id}|${this.props.revision.mw_rev_id}&rvdiffto=${this.props.revision.mw_rev_id}&format=json`;
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
          const firstRevisionData = data.query.pages[this.props.revision.mw_page_id]
                                      .revisions[0];
          const lastRevisionData = data.query.pages[this.props.revision.mw_page_id]
                                      .revisions[1];
          // Data may or may not include the diff.
          let diff;
          if (firstRevisionData.diff) {
            diff = firstRevisionData.diff['*'];
          // Some deleted revisions have a "texthidden" key.
          } else if (firstRevisionData.texthidden === '') {
            diff = '<div class="warning">This revision is not available. It may have been deleted. More details may be available on wiki.</div>';
          }
          this.setState({
            diff: diff,
            comment: firstRevisionData.comment,
            fetched: true,
            firstRevDateTime: firstRevisionData.timestamp,
            lastRevDateTime: lastRevisionData ? lastRevisionData.timestamp : null
          });
        }
      });
  },

  render() {
    let button;
    let showButtonStyle = '';

    if (this.props.revision.wiki.project === 'wikidata') {
      // the DiffViewer does not work for wikidata.org because it doesn't use the same diff format as other wikis,
      // so we're hiding the button
      showButtonStyle = ' hidden';
    }

    if (this.props.largeButton) {
      showButtonStyle = `button dark${showButtonStyle}`;
    } else {
      showButtonStyle = `button dark small${showButtonStyle}`;
    }

    if (this.state.showDiff) {
      button = <button onClick={this.hideDiff} className="pull-right icon-close"></button>;
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

    let diffComment;
    let revisionDateTime;
    let firstRevTime;
    let lastRevTime;
    let timeSpan;
    let editDate;

    // Edit summary for a single revision:
    //  > Edit date and number of characters added
    // Edit summary for range of revisions:
    //  > First and last times for edits to article (from first applicable rev to last)
    if (!this.props.first_revision) {
      revisionDateTime = moment(this.props.revision.date).format('YYYY/MM/DD h:mm a');

      diffComment = <p className="diff-comment">{this.state.comment}</p>;

      editDate = <p className="diff-comment">
        ({I18n.t('revisions.edited_on', { edit_date: revisionDateTime })};&nbsp;
        {this.props.revision.characters}&nbsp;
        {I18n.t('revisions.chars_added')})</p>;
    } else {
      firstRevTime = moment(this.state.firstRevDateTime).format('YYYY/MM/DD h:mm a');
      lastRevTime = moment(this.state.lastRevDateTime).format('YYYY/MM/DD h:mm a');

      timeSpan = I18n.t('revisions.edit_time_span',
                        { first_time: firstRevTime, last_time: lastRevTime });

      editDate = <p className="diff-comment">({timeSpan})</p>;
    }

    let salesforceButtons;
    if (this.props.showSalesforceButton) {
      salesforceButtons = (
        <SalesforceMediaButtons
          course={this.props.course}
          article={this.props.article}
          editors={this.props.editors}
          before_rev_id={this.state.parentRevisionId}
          after_rev_id={this.props.revision.mw_rev_id}
        />
      );
    }

    return (
      <div>
        {button}
        <div className={className}>
          <div className="diff-viewer-header">
            <a className="button dark small" href={wikiDiffUrl} target="_blank">{I18n.t('revisions.view_on_wiki')}</a>
            {button}
            <a className="pull-right button small diff-viewer-feedback" href="/feedback?subject=Diff Viewer" target="_blank">How did the diff viewer work for you?</a>
          </div>
          {salesforceButtons}
          <table>
            <thead>
              <tr>
                <th colSpan="4" className="diff-header">{diffComment}</th>
              </tr>
              <tr>
                <th colSpan="4" className="diff-header">{editDate}</th>
              </tr>
            </thead>
            <tbody dangerouslySetInnerHTML={{ __html: diff }} />
          </table>
        </div>
      </div>
    );
  }
});

export default OnClickOutside(DiffViewer);
