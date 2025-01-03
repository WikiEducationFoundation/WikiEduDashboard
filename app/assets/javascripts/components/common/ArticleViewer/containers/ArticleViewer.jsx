import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';

// Utilities
import { forEach, union } from 'lodash-es';
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

// Constants
import colors from '@components/common/ArticleViewer/constants/colors';

// Actions
import { resetBadWorkAlert, submitBadWorkAlert } from '~/app/assets/javascripts/actions/alert_actions.js';
import { crossCheckArticleTitle } from '@actions/article_actions';

/*
  Quick summary of the ArticleViewer component's main logic

  The 'openArticle()' function opens the 'articleViewer' component.

  If usernames are already available in the props:
    'openArticle()' fetches MediaWiki user IDs for coloration
  If the usernames aren't already available in the props:
    'openArticle()' fetches the usernames
    'useEffect' fetches MediaWiki user IDs for coloration as soon as the usernames are available
*/
const ArticleViewer = ({ showOnMount, users, showArticleFinder, showButtonLabel,
  fetchArticleDetails, assignedUsers, article, course, current_user = {},
  showButtonClass, showPermalink = true, title }) => {
  const [failureMessage, setFailureMessage] = useState(null);
  const [fetched, setFetched] = useState(false);
  const [highlightedHtml, setHighlightedHtml] = useState(null);
  const [showArticle, setShowArticle] = useState(false);
  const [showBadArticleAlert, setShowBadArticleAlert] = useState(false);
  const [whoColorFailed, setWhoColorFailed] = useState(false);
  const [usersState, setUsersState] = useState([]);
  const [userIdsFetched, setUserIdsFetched] = useState(false);
  const [whoColorHtml, setWhoColorHtml] = useState(null);
  const [parsedArticle, setParsedArticle] = useState(null);
  const [unhighlightedContributors, setUnhighlightedContributors] = useState([]);
  const [revisionId, setRevisionId] = useState(null);
  const [pendingRequest, setPendingRequest] = useState(false);
  const lastRevisionId = useSelector(state => state.articleDetails[article.id]?.last_revision?.revid);

  // State to track whether the article title needs to be verified and updated
  // (i.e., if a fetch failed due to the article title being moved)
  const [checkArticleTitle, setCheckArticleTitle] = useState(false);

  const dispatch = useDispatch();
  const ref = useRef();
  const isFirstRender = useRef(true);

  useEffect(() => {
    if (showArticle && users) {
      fetchUserIds();
    }
  }, [showArticle]);

  // Wait for whocolor API to return the raw HTML before highlighting it
  useEffect(() => {
    if (whoColorHtml) {
      highlightAuthors();
    }
  }, [whoColorHtml]);

  // This runs when the user accesses the articleViewer directly from a permalink
  useEffect(() => {
    if (showOnMount) {
      if (users) {
        fetchUserIds();
      }
      if (!showArticle) {
        openArticle();
      }
    }
  }, [showOnMount, users]);

  useEffect(() => {
    if (showArticle) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showArticle]);

  const getShowButtonLabel = () => {
    if (showArticleFinder) return ArticleUtils.I18n('preview', article.project);
    if (showButtonLabel) return showButtonLabel;
    if (isWhocolorLang()) {
      return I18n.t('articles.show_current_version_with_authorship_highlighting');
    }
    return I18n.t('articles.show_current_version');
  };

  // It takes the data sent as the parameter and appends to the current Url
  const addParamToURL = (urlParam) => {
    if (showArticleFinder) { return; }
    window.history.pushState({}, '', `?showArticle=${urlParam}`);
  };

  // It takes a synthetic event to check if it exists
  // It checks if the node(viewer) doesn't exist
  // if either case is true, it removes all parameters from the URL(starting from the ?)
  const removeParamFromURL = (event) => {
    if (showArticleFinder) { return; }
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

    if (!users && !showArticleFinder) {
      fetchArticleDetails();
    } else if (!userIdsFetched && !showArticleFinder) {
      fetchUserIds();
    }
    // WhoColor is only available for some languages
    if (isWhocolorLang()) {
      fetchWhocolorHtml();
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

  const isWhocolorLang = () => {
    // Supported languages for https://wikiwho-api.wmcloud.org as of 2023-05-15
    // See https://github.com/wikimedia/wikiwho_api/blob/main/wikiwho_api/settings_wmcloud.py#L21
    const supported = ['ar', 'de', 'en', 'es', 'eu', 'fr', 'hu', 'id', 'it', 'ja', 'nl', 'pl', 'pt', 'tr'];
    return supported.includes(article.language) && article.project === 'wikipedia';
  };

  // This takes the extended_html from the whoColor API, and replaces the span
  // annotations with ones that are more convenient to style in React.
  // The matching and replacing of spans is tightly coupled to the span format
  // provided by the whoColor API: https://github.com/wikimedia/wikiwho_api
  const highlightAuthors = () => {
    let html = whoColorHtml;
    if (!html) { return; }
    // Array to store user IDs whose contributions couldn't be highlighted
    const unHighlightedUsers = [];

    forEach(usersState, (user, i) => {
      // Move spaces inside spans, so that background color is continuous
      html = html.replace(/ (<span class="editor-token.*?>)/g, '$1 ');

      // Replace each editor span for this user with one that includes their
      // username and color class.
      const prevHtml = html;
      const colorClass = colors[i];
      const styledAuthorSpan = `<span title="${user.name}" class="editor-token token-editor-${user.userid} ${colorClass}`;
      const authorSpanMatcher = new RegExp(`<span class="editor-token token-editor-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);

      if (prevHtml !== html) {
        user.activeRevision = true;
      } else {
        // If highlighting failed , store the un-highlighted user's ID in the editorsID array
        unHighlightedUsers.push(user.userid);
      }
    });

    // Check if there are any editors whose contributions couldn't be highlighted
    if (unHighlightedUsers.length) {
      // If there are unhighlighted editors, call the function to check their contributions in wikitext metadata
      usersContributionExists(unHighlightedUsers);
    } else {
      const status = 'No Unhighlighted Contributors';
      // Set the status of the unhighlightedContributors state to display in the UI
      setUnhighlightedContributors([status]);
    }
    setHighlightedHtml(html);
    setPendingRequest(false);
  };

  // Function to check if contributions of unhighlighted editors exist in the wikitext metadata
  const usersContributionExists = (usersID) => {
    // Create a URL builder and API instance for fetching wikitext metadata
    const builder = new URLBuilder({ article });
    const api = new ArticleViewerAPI({ builder });

    // Fetch wikitext metadata for the current article revision
    api.fetchWikitextMetaData()
       .then((response) => {
         // Extract the tokensForRevision data from the response
         const { tokensForRevision } = response;

         // Iterate through the list of user IDs whose contributions couldn't be highlighted
         usersID.forEach((userID) => {
          // Find a token in the metadata with a matching editor ID
          const foundToken = tokensForRevision.find(token => token.editor === userID.toString());

          // If a token with a matching editor ID is found, it means the user has a contribution
          // in the current revision's wikitext
          if (foundToken) {
            // Add the user ID to the unhighlightedContributors state to display in the UI
            setUnhighlightedContributors(x => [...x, userID]);
          } else {
            const status = `No Contributions Found in this current version for User ID', ${userID}`;
            // If the user ID doesn't have a contribution in the current revision's wikitext,
            // add a message to the unhighlightedContributors state to display in the UI
            setUnhighlightedContributors(x => [...x, status]);
          }
        });
      }).catch((error) => {
      setFailureMessage(error.message);
    });
  };

  const fetchParsedArticle = () => {
    const builder = new URLBuilder({ article });
    const api = new ArticleViewerAPI({ builder });
    setPendingRequest(true);
    api.fetchParsedArticle(revisionId)
      .then((response) => {
        setParsedArticle(response.parsedArticle.html);
        setFetched(response.fetched);
      }).catch((error) => {
        setFailureMessage(error.message);
        setFetched(true);
        setWhoColorFailed(true);
        // Set flag to verify and fetch the article title if the fetch failed, possibly due to the article being moved
        setCheckArticleTitle(true);
      });
  };

  const fetchWhocolorHtml = () => {
    const builder = new URLBuilder({ article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchWhocolorHtml(revisionId)
      .then((response) => {
        setWhoColorHtml(response.html);
      }).catch((error) => {
        setWhoColorFailed(true);
        setFailureMessage(error.message);
        // Set flag to verify and fetch the article title if the fetch failed, possibly due to the article being moved
        setCheckArticleTitle(true);
      });
  };

  // Function to verify if the article title has changed and fetch updated data accordingly
  const verifyAndFetchArticle = async () => {
    // Dispatch an action to cross-check the current article title using its ID and MediaWiki page ID
    const crossCheckedArticleTitle = await dispatch(crossCheckArticleTitle(article.id, article.title, article.mw_page_id));

    if (crossCheckedArticleTitle === article.title) {
      setWhoColorFailed(false); // Clear the failure state for WhoColor data
      setCheckArticleTitle(false); // Stop further title verification checks
      fetchParsedArticle(); // Re-fetch the parsed article content with the current title
      fetchWhocolorHtml(); // Re-fetch the WhoColor HTML for the article using the current title
    } else if (crossCheckArticleTitle !== article.title) {
      setFetched(false); // Indicate a loading state until the Redux store updates the new article title and the component re-renders
    }
  };

  // Trigger the article title verification and data fetching process if a previous fetch failed
  if (checkArticleTitle) {
    verifyAndFetchArticle();
  }


  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  const fetchUserIds = () => {
    /*
      if articleViewer is accessed through Students/Editors tab, a combination
      of both assignedUsers and users will be passed to the URLBuilder.
      However, if the articleViewer is accessed through any other tab. Only the users prop will be passed
      to the URLBuilder as the assignedUsers prop would be undefined.
      In this case, the users prop will be combined with an empty array.
     */
    const allUsers = union(assignedUsers || [], users);
    const builder = new URLBuilder({ article, users: allUsers });
    const api = new ArticleViewerAPI({ builder });
    api.fetchUserIds()
      .then((response) => {
        response.query.users.forEach((user) => {
          user.name = decodeURIComponent(user.name);
          user.activeRevision = false;
        });
        setUsersState(response.query.users);
        setUserIdsFetched(true);
      }).catch((error) => {
        setFailureMessage(error.message);
        setFetched(true);
        setWhoColorFailed(true);
      });
  };

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
    setHighlightedHtml(null);
    setWhoColorHtml(null);
    fetchParsedArticle();
    setUnhighlightedContributors([]);
    if (isWhocolorLang()) {
      fetchWhocolorHtml();
    }
  }, [revisionId]);

  const toggleRevisionHandler = () => {
    if (revisionId) {
      setRevisionId(null);
    } else {
      setRevisionId(lastRevisionId);
    }
  };

  // If the article viewer is hidden, show the icon instead.
  if (!showArticle) {
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
          {
            fetched ? <ParsedArticle highlightedHtml={highlightedHtml} whocolorHtml={whoColorHtml} parsedArticle={parsedArticle} /> : <Loading />
          }
        </div>
        <Footer
          pendingRequest={pendingRequest}
          article={article}
          colors={colors}
          failureMessage={failureMessage}
          isWhocolorLang={isWhocolorLang}
          highlightedHtml={highlightedHtml}
          showArticleFinder={showArticleFinder}
          whoColorFailed={whoColorFailed}
          users={usersState}
          unhighlightedContributors={unhighlightedContributors}
          revisionId={revisionId}
          toggleRevisionHandler={toggleRevisionHandler}
        />
      </div>
    </div>
  );
};

ArticleViewer.defaultProps = {
  showArticleFinder: false
};

ArticleViewer.propTypes = {
  article: PropTypes.shape({
    id: PropTypes.number,
    language: PropTypes.string,
    project: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }),
  course: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func,
  showArticleLegend: PropTypes.bool,
  showButtonLabel: PropTypes.string,
  showButtonClass: PropTypes.string,
  showOnMount: PropTypes.bool,
  title: PropTypes.string,
  users: PropTypes.array,
};

export default (ArticleViewer);
