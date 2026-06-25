import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';

// Utilities
import { trunc } from '~/app/assets/javascripts/utils/strings';
import ArticleUtils from '~/app/assets/javascripts/utils/article_utils';

// Components
import Loading from '@components/common/loading.jsx';
import TitleOpener from '@components/common/ArticleViewer/components/TitleOpener.jsx';
import IconOpener from '@components/common/ArticleViewer/components/IconOpener.jsx';
import CloseButton from '@components/common/ArticleViewer/components/CloseButton.jsx';
import Permalink from '@components/common/ArticleViewer/components/Permalink.jsx';
import BadWorkAlert from '../components/BadWorkAlert/BadWorkAlert';
import BadWorkAlertButton from '@components/common/ArticleViewer/components/BadWorkAlertButton.jsx';
import ParsedArticle from '@components/common/ArticleViewer/components/ParsedArticle.jsx';
import Footer from '@components/common/ArticleViewer/components/Footer.jsx';

// Helpers
import URLBuilder from '@components/common/ArticleViewer/utils/URLBuilder';
import ArticleViewerAPI from '@components/common/ArticleViewer/utils/ArticleViewerAPI';

// Actions
import { resetBadWorkAlert, submitBadWorkAlert } from '~/app/assets/javascripts/actions/alert_actions.js';
import { crossCheckArticleTitle } from '@actions/article_actions';

/*
  ArticleViewerShell is the generic, annotation-agnostic article viewer: it opens
  a modal, fetches the MediaWiki parsed HTML (resolving redirects), transforms
  links, renders the HTML, and provides the footer chrome (revision toggle,
  view-on-wiki, print), the bad-work alert and the ?showArticle= permalink.

  It knows nothing about authorship or claims. An optional highlight feature is
  injected as the `useHighlightFeature` hook, which the shell drives via
  `parsedSettle` (bumped on every parsed-fetch settle, after redirect resolution)
  and `revisionId`. The shell renders the feature's returned slots:
  `html` (replaces the parsed HTML), `banner` (pinned to the top of the article),
  `legend` (footer), `buttonLabel` (opener), `pending` (footer spinner), and
  optionally `onInnerHTMLClick` (a click handler for the injected HTML) and
  `overlay` (a node rendered inside the viewer, e.g. a claim-selection panel). The
  default no-op feature renders the plain parsed HTML.
*/
const noopHighlightFeature = () => ({
  html: null, banner: null, legend: null, buttonLabel: null, pending: false,
  onInnerHTMLClick: undefined, onInnerHTMLKeyDown: undefined, overlay: null,
});

const ArticleViewerShell = ({ showOnMount, users, showArticleFinder, showButtonLabel,
  fetchArticleDetails, assignedUsers, article, course, current_user = {},
  showButtonClass, showPermalink = true, title, useHighlightFeature = noopHighlightFeature,
  renderOpener, initialRevisionId = null }) => {
  const [fetched, setFetched] = useState(false);
  const [showArticle, setShowArticle] = useState(false);
  const [showBadArticleAlert, setShowBadArticleAlert] = useState(false);
  const [parsedArticle, setParsedArticle] = useState(null);
  const [parsedPending, setParsedPending] = useState(false);
  const [parsedSettle, setParsedSettle] = useState(null);
  // A consumer can open the viewer at a specific revision (e.g. the claim
  // exercise opens the article at the AiEditAlert-flagged revision); otherwise
  // it opens at the current version (null).
  const [revisionId, setRevisionId] = useState(initialRevisionId);
  const lastRevisionId = useSelector(state => state.articleDetails[article.id]?.last_revision?.revid);

  // State to track whether the article title needs to be verified and updated
  // (i.e., if a fetch failed due to the article title being moved)
  const [checkArticleTitle, setCheckArticleTitle] = useState(false);

  const dispatch = useDispatch();
  const ref = useRef();
  const isFirstRender = useRef(true);

  // The shell owns parsed/visibility/revision/title state; the highlight feature
  // is told to (re)run via `parsedSettle` and can ask the shell to re-verify the
  // article title. `article` is passed BY REFERENCE: the parsed fetch resolves
  // redirects by mutating `article.title` in place, and the feature's fetches read
  // that resolved title — do not spread/clone `article` on this path.
  const requestTitleVerification = verify => setCheckArticleTitle(verify);
  const feature = useHighlightFeature({
    article, course, users, assignedUsers, showArticleFinder,
    isOpen: showArticle, revisionId, parsedSettle,
    fetchArticleDetails, requestTitleVerification,
  });

  const bumpParsedSettle = (ok, message) =>
    setParsedSettle(prev => ({ id: (prev?.id || 0) + 1, ok, message }));

  useEffect(() => {
    if (showArticle) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showArticle]);

  // This runs when the user accesses the articleViewer directly from a permalink
  useEffect(() => {
    if (showOnMount && !showArticle) {
      openArticle();
    }
  }, [showOnMount]);

  const getShowButtonLabel = () => {
    if (showArticleFinder) return ArticleUtils.I18n('preview', article.project);
    if (showButtonLabel) return showButtonLabel;
    if (feature.buttonLabel) return feature.buttonLabel;
    return I18n.t('articles.show_current_version');
  };

  // It takes the data sent as the parameter and appends to the current Url.
  // The ?showArticle= permalink is only meaningful when this viewer is a modal
  // popped over a page (showPermalink); a standalone viewer (e.g. the claim
  // exercise, showPermalink=false) must leave the page's own query string intact.
  const addParamToURL = (urlParam) => {
    if (showArticleFinder || !showPermalink) { return; }
    window.history.pushState({}, '', `?showArticle=${urlParam}`);
  };

  // It takes a synthetic event to check if it exists
  // It checks if the node(viewer) doesn't exist
  // if either case is true, it removes all parameters from the URL(starting from the ?)
  const removeParamFromURL = (event) => {
    if (showArticleFinder || !showPermalink) { return; }
    const viewer = document.getElementsByClassName('article-viewer')[0];
    if (!viewer || event) {
      if (window.location.search) {
        window.history.replaceState(null, null, window.location.pathname);
      }
    }
  };

  const openArticle = () => {
    setShowArticle(true);
    if (!fetched) {
      fetchParsedArticle();
    }
    // Add article id in the URL
    addParamToURL(article.id);
  };

  const hideArticle = (e) => {
    if (!showArticle) { return; }
    setShowBadArticleAlert(false);
    setShowArticle(false);
    dispatch(resetBadWorkAlert());
    // removes the article parameter from the URL
    removeParamFromURL(e);
  };

  const fetchParsedArticle = () => {
    const builder = new URLBuilder({ article });
    const api = new ArticleViewerAPI({ builder });
    setParsedPending(true);
    api.fetchParsedArticle(revisionId)
      .then((response) => {
        setParsedArticle(response.parsedArticle.html);
        setFetched(response.fetched);
        setParsedPending(false);
        // The title is now resolved (redirects applied in place on `article`);
        // signal the highlight feature to (re)fetch its data.
        bumpParsedSettle(true, null);
      }).catch((error) => {
        setFetched(true);
        setParsedPending(false);
        // Set flag to verify and fetch the article title if the fetch failed, possibly due to the article being moved
        setCheckArticleTitle(true);
        bumpParsedSettle(false, error.message);
      });
  };

  // Function to verify if the article title has changed and fetch updated data accordingly
  const verifyAndFetchArticle = async () => {
    // Dispatch an action to cross-check the current article title using its ID and MediaWiki page ID
    const crossCheckedArticleTitle = await dispatch(crossCheckArticleTitle(article.id, article.title, article.mw_page_id));

    if (crossCheckedArticleTitle === article.title) {
      setCheckArticleTitle(false); // Stop further title verification checks
      fetchParsedArticle(); // Re-fetch; success bumps parsedSettle so the feature re-fetches too
    } else {
      setFetched(false); // Indicate a loading state until the Redux store updates the new article title and the component re-renders
    }
  };

  // Trigger title verification when a fetch fails; re-runs once the Redux store
  // updates `article.title` (so a moved article recovers on the next render).
  useEffect(() => {
    if (checkArticleTitle) {
      verifyAndFetchArticle();
    }
  }, [checkArticleTitle, article.title]);

  const handleClickOutside = (event) => {
    const element = ref.current;
    if (element && !element.contains(event.target)) {
      hideArticle(event);
    }
  };

  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    setParsedArticle(null);
    setFetched(false);
    fetchParsedArticle();
  }, [revisionId]);

  const toggleRevisionHandler = () => {
    if (revisionId) {
      setRevisionId(null);
    } else {
      // Return to the revision the viewer was opened at when one was given
      // (the claim exercise's flagged revision), else the article's last revision.
      setRevisionId(initialRevisionId || lastRevisionId);
    }
  };

  // When closed, render the opener — the surface that reopens the viewer.
  // Consumers can supply their own trigger via `renderOpener` (e.g. the claim
  // exercise, where each article tile is itself the opener and the default
  // launcher icon would serve no purpose); otherwise fall back to the title
  // button or the icon.
  if (!showArticle) {
    if (renderOpener) {
      return renderOpener({ open: openArticle });
    }
    // If a title was provided, show the article viewer with the title.
    if (title) {
      return (
        <TitleOpener
          showArticle={openArticle}
          showButtonClass={showButtonClass}
          showButtonLabel={getShowButtonLabel}
          title={title}
        />
      );
    }
    return (
      <IconOpener
        showArticle={openArticle}
        showButtonClass={showButtonClass}
        showButtonLabel={getShowButtonLabel}
        article={article}
      />
    );
  }

  return (
    <div ref={ref}>
      <div className={`article-viewer ${showArticle ? '' : 'hidden'}`}>
        <div className="article-header">
          <p>
            <span className="article-viewer-title">{trunc(article.title, 56)}</span>
            {
              showPermalink && <Permalink articleId={article.id} />
            }
            <CloseButton hideArticle={hideArticle} />
            {
              current_user.isAdvancedRole && !showArticleFinder ? (
                <BadWorkAlertButton showBadArticleAlert={() => setShowBadArticleAlert(true)} /> // Passed as a function for onclick
              ) : ''
            }
          </p>
        </div>
        {
          showBadArticleAlert && (
            <BadWorkAlert
              project={article.project}
              submitBadWorkAlert={message => dispatch(submitBadWorkAlert({
                article_id: article.id,
                course_id: course.id,
                message
              }))} // Passed as a function that calls dispatch
            />
          )
        }
        <div id="article-scrollbox-id" className="article-scrollbox">
          {feature.banner}
          {
            fetched
              ? <ParsedArticle html={feature.html || parsedArticle} onInnerHTMLClick={feature.onInnerHTMLClick} onInnerHTMLKeyDown={feature.onInnerHTMLKeyDown} />
              : <Loading />
          }
        </div>
        {feature.overlay}
        <Footer
          pendingRequest={parsedPending || feature.pending}
          article={article}
          legend={feature.legend}
          showArticleFinder={showArticleFinder}
          revisionId={revisionId}
          toggleRevisionHandler={toggleRevisionHandler}
        />
      </div>
    </div>
  );
};

ArticleViewerShell.defaultProps = {
  showArticleFinder: false
};

ArticleViewerShell.propTypes = {
  article: PropTypes.shape({
    id: PropTypes.number,
    language: PropTypes.string,
    project: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }),
  course: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func,
  showButtonLabel: PropTypes.string,
  showButtonClass: PropTypes.string,
  showOnMount: PropTypes.bool,
  title: PropTypes.string,
  users: PropTypes.array,
  useHighlightFeature: PropTypes.func,
  // Optional render prop for the closed-state trigger surface; receives
  // `{ open }`. Overrides the default title/icon opener when provided.
  renderOpener: PropTypes.func,
  // Optional MediaWiki revision id to open the article at, instead of the
  // current version (used by the claim exercise for the flagged revision).
  initialRevisionId: PropTypes.number,
};

export default ArticleViewerShell;
