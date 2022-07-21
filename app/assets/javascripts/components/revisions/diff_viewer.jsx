import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import jQuery from 'jquery';
import SalesforceMediaButtons from '../articles/salesforce_media_buttons.jsx';
import Loading from '../common/loading.jsx';
import { toWikiDomain } from '../../utils/wiki_utils';
import { formatWithTime } from '../../utils/date_utils.js';

const DiffViewer = createReactClass({
  displayName: 'DiffViewer',

  // Diff viewer takes a main (final) revision, and optionally a first revision.
  // If a first revision is supplied, it fetches a diff from the parent of the
  // first revision all the way to the main revision.
  // If there is no parent of the first revision — typically because it's the start
  // of a new article — then it uses the first revision as the starting point.
  propTypes: {
    revision: PropTypes.object,
    index: PropTypes.number,
    first_revision: PropTypes.object,
    showButtonLabel: PropTypes.string,
    editors: PropTypes.array,
    showSalesforceButton: PropTypes.bool,
    article: PropTypes.object,
    course: PropTypes.object,
    showButtonClass: PropTypes.string,
    fetchArticleDetails: PropTypes.func,
    setSelectedIndex: PropTypes.func,
    lastIndex: PropTypes.number,
    selectedIndex: PropTypes.number,
    articleTitle: PropTypes.string
  },

  getInitialState() {
    return {
      fetched: false,
    };
  },

  // When 'show' is clicked, this component may or may not already have
  // users data (a list of usernames) in its props. If it does, then 'show' will
  // fetch the MediaWiki user ids, which are used for coloration. Those can't be
  // fetched until the usernames are available, so 'show' will fetch the usernames
  // first in that case. In that case, componentDidUpdate fetches the
  // user ids as soon as usernames are avaialable.
  componentDidUpdate(prevProps, prevState) {
    if (this.shouldShowDiff(this.props) && !prevState.fetched) {
      this.fetchRevisionDetails(this.props);
    }
  },

  // sets the ref for the diff, calls method to resize first empty diff
  setDiffBodyRef(element) {
    this.diffBody = element;
    this.resizeFirstEmptyDiff();
  },

  setSelectedIndex(index) {
    this.props.setSelectedIndex(index);
  },

  // resizes first empty diff element to 50% width in table
  resizeFirstEmptyDiff() {
    if (this.diffBody) {
      const emptyDiff = this.diffBody.querySelector('.diff-empty');
      if (emptyDiff) {
        emptyDiff.setAttribute('style', 'width: 50%;');
      }
    }
  },

  showButtonLabel() {
    if (this.props.showButtonLabel) {
      return this.props.showButtonLabel;
    }
    return I18n.t('revisions.diff_show');
  },

  showDiff() {
    this.setSelectedIndex(this.props.index);
    this.fetchRevisionDetails(this.props);
  },

  fetchRevisionDetails(props) {
    if (!props.editors) {
      props.fetchArticleDetails();
    } else if (!this.state.fetched) {
      this.initiateDiffFetch(props);
    }
  },

  shouldShowDiff(props) {
    return props.selectedIndex === this.props.index;
  },

  hideDiff() {
    this.setSelectedIndex(-1);
  },

  showPreviousArticle() {
    this.setSelectedIndex(this.props.index - 1);
  },

  showNextArticle() {
    this.setSelectedIndex(this.props.index + 1);
  },

  isFirstArticle() {
    return this.props.index === 0;
  },

  isLastArticle() {
    return this.props.index === this.props.lastIndex - 1;
  },

  // If a first and current revision are provided, find the parent of the first revision
  // and get a diff from that parent to the current revision.
  // If only a current revision is provided, get diff to the previous revision.
  initiateDiffFetch(props) {
    if (this.state.diffFetchInitiated) {
      return;
    }
    this.setState({ diffFetchInitiated: true });

    if (props.first_revision) {
      return this.findParentOfFirstRevision(props);
    }
    this.fetchDiff(this.diffUrl(props.revision));
  },

  wikiUrl(revision) {
    return `https://${toWikiDomain(revision.wiki)}`;
  },

  diffUrl(lastRevision, firstRevision) {
    const wikiUrl = this.wikiUrl(lastRevision);
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions&format=json&origin=*&rvprop=ids|timestamp|comment`;
    // eg, "https://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=139993&rvdiffto=prev&format=json",
    let diffUrl;
    if (this.state.parentRevisionId) {
      diffUrl = `${queryBase}&revids=${this.state.parentRevisionId}|${lastRevision.mw_rev_id}&rvdiffto=${lastRevision.mw_rev_id}`;
    } else if (firstRevision) {
      diffUrl = `${queryBase}&revids=${firstRevision.mw_rev_id}|${lastRevision.mw_rev_id}&rvdiffto=${lastRevision.mw_rev_id}`;
    } else {
      diffUrl = `${queryBase}&revids=${lastRevision.mw_rev_id}&rvdiffto=prev`;
    }

    return diffUrl;
  },

  webDiffUrl() {
    const wikiUrl = this.wikiUrl(this.props.revision);
    if (this.state.parentRevisionId) {
      return `${wikiUrl}/w/index.php?oldid=${this.state.parentRevisionId}&diff=${this.props.revision.mw_rev_id}`;
    } else if (this.props.first_revision) {
      return `${wikiUrl}/w/index.php?oldid=${this.props.first_revision.mw_rev_id}&diff=${this.props.revision.mw_rev_id}`;
    }
    return `${wikiUrl}/w/index.php?diff=${this.props.revision.mw_rev_id}`;
  },

  findParentOfFirstRevision(props) {
    const wikiUrl = this.wikiUrl(props.revision);
    const queryBase = `${wikiUrl}/w/api.php?action=query&prop=revisions&origin=*&format=json`;
    const diffUrl = `${queryBase}&revids=${props.first_revision.mw_rev_id}`;
    jQuery.ajax(
      {
        url: diffUrl,
        success: (data) => {
          const revisionData = data.query.pages[props.first_revision.mw_page_id].revisions[0];
          const parentRevisionId = revisionData.parentid;
          this.setState({ parentRevisionId });
          this.fetchDiff(this.diffUrl(props.revision, props.first_revision));
        }
      });
  },

  fetchDiff(diffUrl) {
    jQuery.ajax(
      {
        url: diffUrl,
        success: (data) => {
          let firstRevisionData;
          try {
            firstRevisionData = data.query.pages[this.props.revision.mw_page_id].revisions[0];
          } catch (_err) {
            firstRevisionData = {};
          }
          let lastRevisionData;
          try {
            lastRevisionData = data.query.pages[this.props.revision.mw_page_id].revisions[1];
          } catch (_err) { /* noop */ }

          // Data may or may not include the diff.
          let diff;
          if (firstRevisionData.diff) {
            diff = firstRevisionData.diff['*'];
          } else {
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

  previousArticle() {
    if (this.isFirstArticle()) {
      return null;
    }
    return (
      <button
        onClick={this.showPreviousArticle}
        className="button pull-right dark small"
      >
        {I18n.t('articles.previous')}
      </button>
    );
  },

  nextArticle() {
    if (this.isLastArticle()) {
      return null;
    }
    return (
      <button onClick={this.showNextArticle} className="pull-right margin button dark small">{I18n.t('articles.next')}</button>
    );
  },

  articleDetails() {
    return (
      <div className="diff-viewer-header">
        <p>{this.props.articleTitle}</p>
      </div>
    );
  },

  authorsHTML() {
    return (
      <div className="user-legend-wrap">
        <div className="user-legend">{I18n.t('users.edits_by')}&nbsp;</div>
        <div className="user-legend">{this.props.editors.join(', ')}</div>
      </div>
    );
  },

  render() {
    if (!this.shouldShowDiff(this.props) || !this.props.revision) {
      return (
        <div className={`tooltip-trigger ${this.props.showButtonClass}`}>
          <button onClick={this.showDiff} aria-label="Open Diff Viewer" className="icon icon-diff-viewer"/>
          <div className="tooltip tooltip-center dark large">
            <p>{this.showButtonLabel()}</p>
          </div>
        </div>
      );
    }

    let style = 'hidden';
    if (this.shouldShowDiff(this.props)) {
      style = '';
    }
    const className = `diff-viewer ${style}`;

    let diff;
    if (!this.state.fetched) {
      // div cannot appear as a child of tbody
      diff = <tbody><tr><td><Loading/></td></tr></tbody>;
    } else if (this.state.diff === '') {
      diff = <tbody><tr><td> —</td></tr></tbody>;
    } else {
      // adds a ref for the diff, used to format parts of diff element above
      diff = <tbody dangerouslySetInnerHTML={{ __html: this.state.diff }} ref={this.setDiffBodyRef}/>;
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
      revisionDateTime = formatWithTime(this.props.revision.date);

      diffComment = <p className="diff-comment">{this.state.comment}</p>;

      editDate = (
        <p className="diff-comment">
          ({I18n.t('revisions.edited_on', { edit_date: revisionDateTime })};&nbsp;
          {this.props.revision.characters}&nbsp;
          {I18n.t('revisions.chars_added')})
        </p>);
    } else {
      firstRevTime = formatWithTime(this.state.firstRevDateTime);
      lastRevTime = formatWithTime(this.state.lastRevDateTime);

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
        <div className={className}>
          <div className="diff-viewer-header">
            <a className="button dark small" href={wikiDiffUrl} target="_blank">{I18n.t('revisions.view_on_wiki')}</a>
            <button onClick={this.hideDiff} aria-label="Close Diff Viewer" className="pull-right icon-close"/>
          </div>
          <div className="diff-viewer-header">
            {this.nextArticle()}
            {this.previousArticle()}
          </div>
          <h4>{this.articleDetails()}</h4>
          <div>
            <div className="diff-viewer-scrollbox">
              <strong>{salesforceButtons}</strong>
              <table>
                <thead>
                  <tr>
                    <th colSpan="4" className="diff-header">{diffComment}</th>
                  </tr>
                  <tr>
                    <th colSpan="4" className="diff-header">{editDate}</th>
                  </tr>
                </thead>
                {diff}
              </table>
            </div>
          </div>
          <div className="diff-viewer-footer">
            {this.authorsHTML()}
          </div>
        </div>
      </div>
    );
  }
});

export default DiffViewer;
