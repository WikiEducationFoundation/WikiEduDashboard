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
        let res;
        // The 'unhighlightedContributions' keeps track of the userids of users whose contributions
        // were not successfully highlighted in the article viewer.
        const UnhighlightedContributions = unhighlightedContributors?.find(x => x === user.userid);
        const userLink = UserUtils.userTalkUrl(user.name, article.language, article.project);
        const fullUserRecord = allUsers.find(_user => _user.username === user.name);
        const realName = fullUserRecord && fullUserRecord.real_name;
        if (status === 'loading') {
          res = <div key={`legend-${user.name}`} className={'article-viewer-legend'}><a href={userLink} title={realName} target="_blank">{user.name}</a></div>;
        } else if (user.activeRevision === true) {
          res = <div key={`legend-${user.name}`} className={`article-viewer-legend user-legend-name ${colors[i]}`}><a href={userLink} title={realName} target="_blank">{user.name}</a><img className="user-legend-hover" style={{ color: 'transparent' }} src="/assets/images/arrow.svg" alt="scroll to users revisions" width="30px" height="20px" onClick={() => Scroller.scrollTo(user.name, scrollBox)} /></div >;
        } else if (UnhighlightedContributions) {
          res = <div key={`legend-${user.name}`} className={'article-viewer-legend tooltip-trigger'}><p className={'tooltip large'} id={'popup-style'} >{I18n.t('users.contributions_not_highlighted', { username: user.name })}</p><a href={userLink} title={realName} target="_blank">{user.name}</a>{<span className="tooltip-indicator-article-viewer" />}</div>;
        } else {
          res = <div key={`legend-${user.name}`} className={'article-viewer-legend tooltip-trigger'}><p className={'tooltip large'} id={'popup-style'}>{I18n.t('users.no_highlighting', { editor: user.name })}</p><a href={userLink} title={realName} target="_blank">{user.name}</a>{<span className="tooltip-indicator-article-viewer" />}</div>;
        }

        return res;
      }));
    } else {
      setUserLinks(<div className="article-viewer-legend authorship-loading"> &nbsp; &nbsp; </div>);
    }
  }, [users, status, unhighlightedContributors]);

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
