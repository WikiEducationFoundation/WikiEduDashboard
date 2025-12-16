import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import UserUtils from '../../utils/user_utils.js';

import ArticleScroll from '@components/common/ArticleViewer/utils/ArticleScroll';

const ArticleViewerLegend = ({ article, users, colors, status, allUsers, failureMessage, unhighlightedContributors }) => {
  const [userLinks, setUserLinks] = useState('');
  const [usersStatus, setUsersStatus] = useState('');
  const Scroller = new ArticleScroll();

  useEffect(() => {
  if (users) {
    const scrollBox = document.querySelector('#article-scrollbox-id');
    let titles = null;
    if (scrollBox !== null) {
      titles = scrollBox.querySelectorAll('p, li, h2, h3');
    }

    if (titles !== null) {
      Scroller.createScrollObject(titles, users);
    }

    setUserLinks(users.map((user, i) => {
      // The 'unhighlightedContributions' keeps track of the userids of users whose contributions
      // were not successfully highlighted in the article viewer.
      const UnhighlightedContributions = unhighlightedContributors?.find(x => x === user.userid);
      const userLink = UserUtils.userTalkUrl(user.name, article.language, article.project);
      const fullUserRecord = allUsers.find(_user => _user.username === user.name);
      const realName = fullUserRecord && fullUserRecord.real_name;
      const colorClass = colors[i];

      const handleScroll = () => {
        if (!scrollBox) return;

        const target = Scroller.scrollTo(user.name, scrollBox);

        if (target && typeof target.focus === 'function') {
          // Make sure it can receive programmatic focus
          if (!target.hasAttribute('tabindex')) {
            target.setAttribute('tabindex', '-1');
          }
          target.focus();
        }
      };

      // Accessible label for the scroll button, tailored by state
      let scrollAriaLabel;
      if (status === 'loading') {
        scrollAriaLabel = I18n.t('users.loading_authorship_for', { username: user.name });
      } else if (user.activeRevision === true) {
        scrollAriaLabel = I18n.t('users.scroll_to_users_edits', { username: user.name });
      } else if (UnhighlightedContributions) {
        scrollAriaLabel = I18n.t('users.contributions_not_highlighted', { username: user.name });
      } else {
        scrollAriaLabel = I18n.t('users.no_highlighting', { editor: user.name });
      }

      const isClickable = status !== 'loading' && user.activeRevision === true;

      // Common wrapper class
      const wrapperClassNames = [
        'article-viewer-legend',
        'user-legend-name',
        (user.activeRevision === true ? colorClass : ''),
        (UnhighlightedContributions || (!user.activeRevision && status !== 'loading') ? 'tooltip-trigger' : '')
      ].filter(Boolean).join(' ');

      // Base button element: focusable, screen-reader friendly
      const scrollButton = isClickable && (
        <button
          type="button"
          className="article-viewer-legend-button"
          onClick={handleScroll}
          aria-label={scrollAriaLabel}
        >
          <span aria-hidden="false">{user.name}</span>
          <img className="user-legend-hover" style={{ color: 'transparent' }} src="/assets/images/arrow.svg" alt="" width="30px" height="20px" />
        </button>
      );

      let tooltip = null;
      if (status === 'loading') {
        // No tooltip; message handled in usersStatus
        tooltip = null;
      } else if (user.activeRevision === true) {
        // Active user — no tooltip needed, label explains behavior
        tooltip = null;
      } else if (UnhighlightedContributions) {
        tooltip = (
          <p className="tooltip large" id="popup-style">
            {I18n.t('users.contributions_not_highlighted', { username: user.name })}
          </p>
        );
      } else {
        tooltip = (
          <p className="tooltip large" id="popup-style">
            {I18n.t('users.no_highlighting', { editor: user.name })}
          </p>
        );
      }

      // Separate link to user talk page for mouse / keyboard / SR users
      const talkLink = (
        <a
          href={userLink}
          title={realName || user.name}
          target="_blank"
          rel="noopener noreferrer"
          className="user-legend-talk-link"
          aria-label="View User Page"
        >
          {/* Simple visual hint; marked aria-hidden so SR users rely on sr-only text */}
          <span aria-hidden="true">↗</span>
        </a>
      );

      return (
        <div key={`legend-${user.name}`} className={wrapperClassNames}>
          {tooltip}
          {scrollButton}
          {talkLink}
        </div>
      );
    }));
  } else {
    setUserLinks(<div className="article-viewer-legend authorship-loading"> &nbsp; &nbsp; </div>);
  }
}, [users, status, unhighlightedContributors, allUsers, article.language, article.project]);


  useEffect(() => {
    if (status === 'loading') {
      setUsersStatus(
        <div>
          <div className="article-viewer-legend authorship-loading"> &nbsp; &nbsp; </div>
          <div className="article-viewer-legend authorship-status">{I18n.t('users.loading_authorship_data')}</div>
          <div className="article-viewer-legend authorship-loading"> &nbsp; &nbsp; </div>
        </div>
      );
    } else if (status === 'failed') {
      setUsersStatus(<div className="article-viewer-legend authorship-status-failed">{I18n.t('users.authorship_data_not_fetched')}: {failureMessage}</div>);
    } else if (status === 'ready') {
      setUsersStatus('');
    }
  }, [status]);

  return (
    <div className="user-legend-wrap">
      <div className="article-viewer-legend">{I18n.t('users.edits_by')}&nbsp;</div>
      {userLinks}
      {usersStatus}
    </div>
  );
};

ArticleViewerLegend.propTypes = {
  article: PropTypes.object,
  users: PropTypes.array,
  colors: PropTypes.array,
  status: PropTypes.string
};

const mapStateToProps = state => ({
  allUsers: state.users.users
});

export default connect(mapStateToProps)(ArticleViewerLegend);
