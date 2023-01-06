import React from 'react';
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

export class ArticleViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      failureMessage: null,
      fetched: false,
      highlightedHtml: null,
      showArticle: false,
      showBadArticleAlert: false,
      whocolorFailed: false,
      users: []
    };

    this.showArticle = this.showArticle.bind(this);
    this.showButtonLabel = this.showButtonLabel.bind(this);
    this.hideArticle = this.hideArticle.bind(this);
    this.hideBadArticleAlert = this.hideBadArticleAlert.bind(this);
    this.showBadArticleAlert = this.showBadArticleAlert.bind(this);
    this.submitBadWorkAlert = this.submitBadWorkAlert.bind(this);
    this.isWhocolorLang = this.isWhocolorLang.bind(this);
    this.handleClickOutside = this.handleClickOutside.bind(this);
    this.ref = React.createRef();
  }

  componentDidMount() {
    if (this.props.showOnMount) {
      this.showArticle();
    }
  }

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
  componentDidUpdate(prevProps, prevState) {
    if (!prevProps.users && this.props.users) {
        if (!prevState.userIdsFetched) {
          this.fetchUserIds();
      }
    }
    if (!prevState.showArticle && this.state.showArticle) {
      // Add event listener when the component is visible
      document.addEventListener('mousedown', this.handleClickOutside);
    }
    if (prevState.showArticle && !this.state.showArticle) {
      // Remove event listener when the component is hidden
      document.removeEventListener('mousedown', this.handleClickOutside);
    }
  }

  hideBadArticleAlert() {
    this.setState({ showBadArticleAlert: false });
  }

  showBadArticleAlert() {
    this.setState({ showBadArticleAlert: true });
  }

  showButtonLabel() {
    const { showArticleFinder, showButtonLabel } = this.props;
    if (showArticleFinder) return ArticleUtils.I18n('preview', this.props.article.project);
    if (showButtonLabel) return showButtonLabel;
    if (this.isWhocolorLang()) {
      return I18n.t('articles.show_current_version_with_authorship_highlighting');
    }
    return I18n.t('articles.show_current_version');
  }

  // It takes the data sent as the parameter and appends to the current Url
  addParamToURL(urlParam) {
    if (this.props.showArticleFinder) { return; }
    window.history.pushState({}, '', `?showArticle=${urlParam}`);
  }

  // It takes a synthetic event to check if it exist
  // It checks if the node(viewer) doesn't exist
  // if either case is true, it removes all parameters from the URL(starting from the ?)
  removeParamFromURL(event) {
    if (this.props.showArticleFinder) { return; }
    const viewer = document.getElementsByClassName('article-viewer')[0];
    if (!viewer || event) {
      if (window.location.search) {
        window.history.replaceState(null, null, window.location.pathname);
      }
    }
  }

  showArticle() {
    this.setState({ showArticle: true });
    if (!this.state.fetched) {
      this.fetchParsedArticle();
    }

    if (!this.props.users && !this.props.showArticleFinder) {
      this.props.fetchArticleDetails();
    } else if (!this.state.userIdsFetched && !this.props.showArticleFinder) {
      this.fetchUserIds();
    }
    // WhoColor is only available for some languages
    if (!this.state.whocolorFetched && this.isWhocolorLang()) {
      this.fetchWhocolorHtml();
    }
    // Add article id in the URL
    this.addParamToURL(this.props.article.id);
  }

  hideArticle(e) {
    if (!this.state.showArticle) { return; }
    this.hideBadArticleAlert();
    this.setState({ showArticle: false });
    this.props.resetBadWorkAlert();
    // removes the article parameter from the URL
    this.removeParamFromURL(e);
  }

  isWhocolorLang() {
    // Supported languages for https://api.wikiwho.net/ as of 2018-02-11
    const { article } = this.props;
    const supported = ['de', 'en', 'es', 'eu', 'tr'];
    return supported.includes(article.language) && article.project === 'wikipedia';
  }

  // This takes the extended_html from the whoColor API, and replaces the span
  // annotations with ones that are more convenient to style in React.
  // The matching and replacing of spans is tightly coupled to the span format
  // provided by the whoColor API: https://github.com/wikiwho/WhoColor
  highlightAuthors() {
    let html = this.state.whocolorHtml;
    if (!html) { return; }
    let i = 0;
    forEach(this.state.users, (user) => {
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
    this.setState({ highlightedHtml: html });
  }

  fetchParsedArticle() {
    const builder = new URLBuilder({ article: this.props.article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchParsedArticle()
      .then((response) => {
        this.setState({
          ...response,
          parsedArticle: response.parsedArticle.html
        });
      }).catch((error) => {
        this.setState({
          failureMessage: error.message,
          fetched: true,
          whocolorFailed: true,
        });
      });
  }

  fetchWhocolorHtml() {
    const builder = new URLBuilder({ article: this.props.article });
    const api = new ArticleViewerAPI({ builder });
    api.fetchWhocolorHtml()
      .then((response) => {
        this.setState({ whocolorHtml: response.html });
        this.highlightAuthors();
      }).catch((error) => {
        this.setState({
          whocolorFailed: true,
          failureMessage: error.message
        });
      });
  }

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  fetchUserIds() {
    // if articleViewer is accessed through Students/Editors tab, a combination
    // of both assignedUsers and users will be passed to the URLBuilder, whenever the
    // fetchUserIds function is called. However, if the articleViewer is accessed
    // through any other tab, e.g Articles tab, only the users prop will be passed
    // to the URLBuilder as the assignedUsers prop would be undefined. In this case
    // the users prop will be combined with an empty array.
    const users = union(this.props.assignedUsers || [], this.props.users);
    const builder = new URLBuilder({ article: this.props.article, users });
    const api = new ArticleViewerAPI({ builder });
    api.fetchUserIds()
      .then((response) => {
        response.query.users.forEach((user) => {
          user.name = decodeURIComponent(user.name);
          user.activeRevision = false;
        });
        this.setState({
          users: response.query.users,
          userIdsFetched: true
        });
      }).catch((error) => {
        this.setState({
          failureMessage: error.message,
          fetched: true,
          whocolorFailed: true,
        });
      });
  }

  submitBadWorkAlert(message) {
    this.props.submitBadWorkAlert({
      article_id: this.props.article.id,
      course_id: this.props.course.id,
      message
    });
  }

  handleClickOutside(event) {
    const element = this.ref.current;
    if (element && !element.contains(event.target)) {
      this.hideArticle(event);
    }
  }

  render() {
    const {
      alertStatus, article, current_user = {}, showButtonClass, showPermalink = true,
      showArticleFinder, title
    } = this.props;
    const {
      failureMessage, fetched, highlightedHtml, showArticle,
      showBadArticleAlert, whocolorFailed, users
    } = this.state;

    // If the article viewer is hidden, show the icon instead.
    if (!showArticle) {
      // If a title was provided, show the article viewer with the title.
      if (title) {
        return (
          <TitleOpener
            showArticle={this.showArticle}
            showButtonClass={showButtonClass}
            showButtonLabel={this.showButtonLabel}
            title={title}
          />
        );
      }
      return (
        <IconOpener
          showArticle={this.showArticle}
          showButtonClass={showButtonClass}
          showButtonLabel={this.showButtonLabel}
          article={this.props.article}
        />
      );
    }

    return (
      <div ref={this.ref}>
        <div className={`article-viewer ${showArticle ? '' : 'hidden'}`}>
          <div className="article-header">
            <p>
              <span className="article-viewer-title">{trunc(article.title, 56)}</span>
              {
                showPermalink && <Permalink articleId={article.id} />
              }
              <CloseButton hideArticle={this.hideArticle} />
              {
                current_user.isAdvancedRole && (
                  <BadWorkAlertButton showBadArticleAlert={this.showBadArticleAlert} />
                )
              }
            </p>
          </div>
          {
            showBadArticleAlert && (
              <BadWorkAlert
                alertStatus={alertStatus}
                project={this.props.article.project}
                submitBadWorkAlert={this.submitBadWorkAlert}
              />
            )
          }
          <div id="article-scrollbox-id" className="article-scrollbox">
            {
              fetched ? <ParsedArticle {...this.state} /> : <Loading />
            }
          </div>
          <Footer
            article={article}
            colors={colors}
            failureMessage={failureMessage}
            isWhocolorLang={this.isWhocolorLang}
            highlightedHtml={highlightedHtml}
            showArticleFinder={showArticleFinder}
            whocolorFailed={whocolorFailed}
            users={users}
          />
        </div>
      </div>
    );
  }
}

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
