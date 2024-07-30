import React, { useState, useEffect, useRef } from "react";
import PropTypes from "prop-types";
import SalesforceMediaButtons from "../articles/salesforce_media_buttons.jsx";
import Loading from "../common/loading.jsx";
import { toWikiDomain } from "../../utils/wiki_utils";
import { formatDateWithTime } from "../../utils/date_utils.js";

const DiffViewer = (props) => {
  const [state, setState] = useState({
    fetched: false,
    diffFetchInitiated: false,
    parentRevisionId: null,
    diff: "",
    comment: "",
    firstRevDateTime: null,
    lastRevDateTime: null,
  });

  const diffBodyRef = useRef(null);

  useEffect(() => {
    if (shouldShowDiff(props) && !state.fetched) {
      fetchRevisionDetails(props);
    }
  }, [props, state.fetched]);

  const setSelectedIndex = (index) => {
    props.setSelectedIndex(index);
  };

  const resizeFirstEmptyDiff = () => {
    const emptyDiff = diffBodyRef.current.querySelector(".diff-empty");
    if (emptyDiff) {
      emptyDiff.setAttribute("style", "width: 50%;");
    }
  };

  const showButtonLabel = () => {
    return props.showButtonLabel
      ? props.showButtonLabel
      : I18n.t("revisions.diff_show");
  };

  const showDiff = () => {
    setSelectedIndex(props.index);
    fetchRevisionDetails();
  };

  const fetchRevisionDetails = () => {
    if (!props.editors) {
      props.fetchArticleDetails();
    } else if (!state.fetched) {
      initiateDiffFetch();
    }
  };

  const shouldShowDiff = () => {
    return props.selectedIndex === props.index;
  };

  const hideDiff = () => {
    setSelectedIndex(-1);
  };

  const showPreviousArticle = () => {
    setSelectedIndex(props.index - 1);
  };

  const showNextArticle = () => {
    setSelectedIndex(props.index + 1);
  };

  const isFirstArticle = () => {
    return props.index === 0;
  };

  const isLastArticle = () => {
    return props.index === props.lastIndex - 1;
  };

  const wikiUrl = (revision) => {
    return `https://${toWikiDomain(revision.wiki)}`;
  };

  const diffUrl = (lastRevision, firstRevision) => {
    const wikiUrlStr = wikiUrl(lastRevision);
    const queryBase = `${wikiUrlStr}/w/api.php?action=query&prop=revisions&format=json&origin=*&rvprop=ids|timestamp|comment`;
    let diffUrlStr;
    if (state.parentRevisionId) {
      diffUrlStr = `${queryBase}&revids=${state.parentRevisionId}|${lastRevision.mw_rev_id}&rvdiffto=${lastRevision.mw_rev_id}`;
    } else if (firstRevision) {
      diffUrlStr = `${queryBase}&revids=${firstRevision.mw_rev_id}|${lastRevision.mw_rev_id}&rvdiffto=${lastRevision.mw_rev_id}`;
    } else {
      diffUrlStr = `${queryBase}&revids=${lastRevision.mw_rev_id}&rvdiffto=prev`;
    }
    return diffUrlStr;
  };

  const webDiffUrl = () => {
    const wikiUrlStr = wikiUrl(props.revision);
    if (state.parentRevisionId) {
      return `${wikiUrlStr}/w/index.php?oldid=${state.parentRevisionId}&diff=${props.revision.mw_rev_id}`;
    } else if (props.first_revision) {
      return `${wikiUrlStr}/w/index.php?oldid=${props.first_revision.mw_rev_id}&diff=${props.revision.mw_rev_id}`;
    }
    return `${wikiUrlStr}/w/index.php?diff=${props.revision.mw_rev_id}`;
  };

  const findParentOfFirstRevision = () => {
    const wikiUrlStr = wikiUrl(props.revision);
    const queryBase = `${wikiUrlStr}/w/api.php?action=query&prop=revisions&origin=*&format=json`;
    const diffUrlStr = `${queryBase}&revids=${props.first_revision.mw_rev_id}`;

    fetch(diffUrlStr)
      .then((resp) => resp.json())
      .then((data) => {
        const revisionData =
          data.query.pages[props.first_revision.mw_page_id].revisions[0];
        const parentRevisionId = revisionData.parentid;
        setState((prevState) => ({ ...prevState, parentRevisionId }));
        fetchDiff(diffUrl(props.revision, props.first_revision));
      });
  };

  const fetchDiff = (diffUrlStr) => {
    fetch(diffUrlStr)
      .then((resp) => resp.json())
      .then((data) => {
        let firstRevisionData = {};
        let lastRevisionData = null;
        try {
          firstRevisionData =
            data.query.pages[props.revision.mw_page_id].revisions[0];
        } catch (_err) {
          /* noop */
        }
        try {
          lastRevisionData =
            data.query.pages[props.revision.mw_page_id].revisions[1];
        } catch (_err) {
          /* noop */
        }

        let diffContent =
          '<div class="warning">This revision is not available. It may have been deleted. More details may be available on wiki.</div>';
        if (firstRevisionData.diff) {
          diffContent = firstRevisionData.diff["*"];
        }

        setState((prevState) => ({
          ...prevState,
          diff: diffContent,
          comment: firstRevisionData.comment,
          fetched: true,
          firstRevDateTime: firstRevisionData.timestamp,
          lastRevDateTime: lastRevisionData ? lastRevisionData.timestamp : null,
        }));
      });
  };

  const initiateDiffFetch = () => {
    if (state.diffFetchInitiated) {
      return;
    }
    setState((prevState) => ({ ...prevState, diffFetchInitiated: true }));

    if (props.first_revision) {
      return findParentOfFirstRevision();
    }
    fetchDiff(diffUrl(props.revision));
  };

  const previousArticle = () => {
    if (isFirstArticle()) {
      return null;
    }
    return (
      <button
        onClick={showPreviousArticle}
        className="button pull-right dark small"
      >
        {I18n.t("articles.previous")}
      </button>
    );
  };

  const nextArticle = () => {
    if (isLastArticle()) {
      return null;
    }
    return (
      <button
        onClick={showNextArticle}
        className="pull-right margin button dark small"
      >
        {I18n.t("articles.next")}
      </button>
    );
  };

  const articleDetails = () => {
    return (
      <div className="diff-viewer-header">
        <p>{props.articleTitle}</p>
      </div>
    );
  };

  if (!shouldShowDiff() || !props.revision) {
    return (
      <div className={`tooltip-trigger ${props.showButtonClass}`}>
        <button
          onClick={showDiff}
          aria-label="Open Diff Viewer"
          className="icon icon-diff-viewer"
        />
        <div className="tooltip tooltip-center dark large">
          <p>{showButtonLabel()}</p>
        </div>
      </div>
    );
  }

  let style = "hidden";
  if (shouldShowDiff()) {
    style = "";
  }
  const className = `diff-viewer ${style}`;

  let diff;
  if (!state.fetched) {
    diff = (
      <tbody>
        <tr>
          <td>
            <Loading />
          </td>
        </tr>
      </tbody>
    );
  } else if (state.diff === "") {
    diff = (
      <tbody>
        <tr>
          <td> —</td>
        </tr>
      </tbody>
    );
  } else {
    diff = (
      <tbody
        dangerouslySetInnerHTML={{ __html: state.diff }}
        ref={diffBodyRef}
      />
    );
  }

  const wikiDiffUrlStr = webDiffUrl();

  let diffComment;
  let firstRevTime;
  let lastRevTime;
  let timeSpan;
  let editDate;
  let formattedDate;
  let charactersCount;
  let finalDate;

  if (!props.first_revision) {
    formattedDate = formatDateWithTime(props.revision.date);
    editDate = I18n.t("revisions.edited_on", { edit_date: formattedDate });
    finalDate = (
      <div className="diff-viewer-legend" style={{ width: "66%" }}>
        {editDate}
      </div>
    );
    charactersCount = (
      <div className="diff-viewer-legend">
        {props.revision.characters} {I18n.t("revisions.chars_added")}
      </div>
    );
  } else {
    firstRevTime = formatDateWithTime(state.firstRevDateTime);
    lastRevTime = formatDateWithTime(state.lastRevDateTime);
    timeSpan = I18n.t("revisions.edit_time_span", {
      first_time: firstRevTime,
      last_time: lastRevTime,
    });
    editDate = <p className="diff-comment">{timeSpan}</p>;
    finalDate = (
      <div className="diff-viewer-legend" style={{ width: "66%" }}>
        {editDate}
      </div>
    );
  }
  const final = (
    <div className="user-legend-wrap">
      <div
        className="diff-viewer-legend"
        style={{ justifyContent: "flex-start" }}
      >
        {I18n.t("users.edits_by")}{" "}
        <a href={props.userUrl} target="_blank">
          {props.revision.user}
        </a>
      </div>
      {finalDate}
      {charactersCount}
    </div>
  );

  return (
    <div className={className} key={`diff_${props.revision.id}`}>
      <div className="section-header">
        <button
          onClick={hideDiff}
          className="pull-right article-viewer button dark small"
        >
          {I18n.t("revisions.diff_hide")}
        </button>
        {articleDetails()}
      </div>
      <div className="diff-viewer-scrollbox">
        <table className="diff-table diff">
          <thead>
            <tr>
              <td className="diff-title" colSpan="2">
                <p>
                  <a href={wikiDiffUrlStr} target="_blank">
                    {I18n.t("revisions.full_diff")}
                  </a>
                  {state.comment}
                </p>
                {diffComment}
              </td>
            </tr>
          </thead>
          {diff}
        </table>
      </div>
      {final}
      <div className="preview-nav">
        {nextArticle()}
        {previousArticle()}
      </div>
      <SalesforceMediaButtons
        article={props.article}
        course={props.course}
        current_user={props.current_user}
        wikidataLabels={props.wikidataLabels}
      />
    </div>
  );
};

DiffViewer.propTypes = {
  index: PropTypes.number.isRequired,
  lastIndex: PropTypes.number.isRequired,
  setSelectedIndex: PropTypes.func.isRequired,
  selectedIndex: PropTypes.number.isRequired,
  revision: PropTypes.object,
  first_revision: PropTypes.object,
  article: PropTypes.object.isRequired,
  articleTitle: PropTypes.string,
  userUrl: PropTypes.string,
  fetchArticleDetails: PropTypes.func,
  editors: PropTypes.array,
  showButtonLabel: PropTypes.string,
  showButtonClass: PropTypes.string,
  course: PropTypes.object,
  current_user: PropTypes.object,
  wikidataLabels: PropTypes.object,
};

export default DiffViewer;
