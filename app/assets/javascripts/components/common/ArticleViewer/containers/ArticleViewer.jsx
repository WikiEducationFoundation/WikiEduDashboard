import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

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

// const usePreviousValue = (value) => {
//   const ref = useRef();
//   useEffect(() => {
//     ref.current = value;
//   });
//   return ref.current;
// };

const ArticleViewer = ({ showOnMount, users, showArticleFinder, showButtonLabel, fetchArticleDetails, assignedUsers, article, course,
  alertStatus, current_user = {}, showButtonClass, showPermalink = true, title, ...props }) => {
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

  const ref = useRef();

  // const prevUsers = usePreviousValue(users);
  // const prevUserIdsFetched = usePreviousValue(userIdsFetched);

  // useEffect(() => {
  //     console.log('prevUsers:', prevUsers, 'users:', users, 'prevUserIdsFetched:', prevUserIdsFetched);
  //     if (!prevUsers && users) {
  //       if (!prevUserIdsFetched) {
  //         fetchUserIds();
  //       }
  //     }
  //   }, []);

  useEffect(() => {
    if (showOnMount) {
      openArticle();
    }
  }, [showOnMount]);

  // When 'show' is clicked, this component may or may not already have
  // users data (a list of usernames) in its props. If it does, then 'show' will
  // fetch the MediaWiki user ids, which are used for coloration. Those can't be
  // fetched until the usernames are available, so 'show' will fetch the usernames
  // first in that case. In that case, componentDidUpdate fetches the
  // user ids as soon as usernames are avaialable. In case the articleViewer is
  // accessed through the Students/Editors tab, an extra prop called assignedUsers,that
  // holds all users extracted from assigned articles, will be passed to the articleViewer in
  // addition to the users prop, which in this case contains all the users that have edited
  // the article but not been assigned to it. The assignedUsers prop, if available, is then
  // used in the fetchUserIds function.

  useEffect(() => {
    if (users && !userIdsFetched) {
      fetchUserIds();
    }
  }, [users, userIdsFetched]);

  useEffect(() => {
    if (showArticle) {
      // Add event listener when the component is visible
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
    props.resetBadWorkAlert();
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
    let i = 0;
    forEach(usersState, (user) => {
      // Move spaces inside spans, so that background color is continuous
      html = html.replace(/ (<span class="editor-token.*?>)/g, '$1 ');

      // Replace each editor span for this user with one that includes their
      // username and color class.
      const prevHtml = html;
      const colorClass = colors[i];
      const styledAuthorSpan = `<span title="${user.name}" class="editor-token token-editor-${user.userid} ${colorClass}`;
      const authorSpanMatcher = new RegExp(`<span class="editor-token token-editor-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);
      if (prevHtml !== html) user.activeRevision = true;
      i += 1;
    });
    setHighlightedHtml(html);
  };

  const fetchParsedArticle = () => {
    const builder = new URLBuilder({ article: article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchParsedArticle()
      .then((response) => {
        setParsedArticle(response.parsedArticle.html);
        setFetched(response.fetched);
      }).catch((error) => {
        setFailureMessage(error.message);
        setFetched(true);
        setWhoColorFailed(true);
      });
  };

  const fetchWhocolorHtml = () => {
    const builder = new URLBuilder({ article: article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchWhocolorHtml()
      .then((response) => {
        setWhoColorHtml(response.html);
        highlightAuthors();
      }).catch((error) => {
        setWhoColorFailed(true);
        setFailureMessage(error.message);
      });
  };

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  const fetchUserIds = () => {
    // if articleViewer is accessed through Students/Editors tab, a combination
    // of both assignedUsers and users will be passed to the URLBuilder, whenever the
    // fetchUserIds function is called. However, if the articleViewer is accessed
    // through any other tab, e.g Articles tab, only the users prop will be passed
    // to the URLBuilder as the assignedUsers prop would be undefined. In this case
    // the users prop will be combined with an empty array.
    const allUsers = union(assignedUsers || [], users);
    const builder = new URLBuilder({ article: article, users: allUsers });
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

  const _submitBadWorkAlert = (message) => {
    props.submitBadWorkAlert({
      article_id: article.id,
      course_id: course.id,
      message
    });
  };

  const handleClickOutside = (event) => {
    const element = ref.current;
    if (element && !element.contains(event.target)) {
      hideArticle(event);
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
              current_user.isAdvancedRole && (
                <BadWorkAlertButton showBadArticleAlert={showBadArticleAlert} />
              )
            }
          </p>
        </div>
        {
          showBadArticleAlert && (
            <BadWorkAlert
              alertStatus={alertStatus}
              project={article.project}
              submitBadWorkAlert={_submitBadWorkAlert}
            />
          )
        }
        <div id="article-scrollbox-id" className="article-scrollbox">
          {
            fetched ? <ParsedArticle highlightedHtml={highlightedHtml} whocolorHtml={whoColorHtml} parsedArticle={parsedArticle} /> : <Loading />
          }
        </div>
        <Footer
          article={article}
          colors={colors}
          failureMessage={failureMessage}
          isWhocolorLang={isWhocolorLang}
          highlightedHtml={highlightedHtml}
          showArticleFinder={showArticleFinder}
          whoColorFailed={whoColorFailed}
          users={usersState}
        />
      </div>
    </div>
  );
};

ArticleViewer.defaultProps = {
  showArticleFinder: false
};

ArticleViewer.propTypes = {
  alertStatus: PropTypes.object.isRequired,
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

const mapStateToProps = ({ badWorkAlert }) => ({ alertStatus: badWorkAlert });
const mapDispatchToProps = {
  resetBadWorkAlert,
  submitBadWorkAlert
};
export default connect(mapStateToProps, mapDispatchToProps)(ArticleViewer);
