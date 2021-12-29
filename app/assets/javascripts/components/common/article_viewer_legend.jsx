import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import ArticleUtils from '../../utils/article_utils.js';


import UserUtils from '../../utils/user_utils.js';
// import Scroll from 'react-scroll';

import ArticleScroll from '@components/common/ArticleViewer/utils/ArticleScroll';

const ArticleViewerLegend = ({ article, users, colors, status, allUsers, failureMessage }) => {
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
        const userLink = UserUtils.userTalkUrl(user.name, article.language, article.project);
        const fullUserRecord = allUsers.find(_user => _user.username === user.name);
        const realName = fullUserRecord && fullUserRecord.real_name;
        if (status === 'loading') {
          res = <div key={`legend-${user.name}`} className={'user-legend'}><a href={userLink} title={realName} target="_blank">{user.name}</a></div>;
        } else if (user.activeRevision === true) {
          res = <div key={`legend-${user.name}`} className={`user-legend ${colors[i]}`}><a href={userLink} title={realName} target="_blank">{user.name}</a><img className="user-legend-hover" style={{ color: 'transparent' }} src="/assets/images/arrow.svg" alt="scroll to users revisions" width="30px" height="20px" onClick={() => Scroller.scrollTo(user.name, scrollBox)} /></div >;
        } else {
          res = <div key={`legend-${user.name}`} className={'user-legend tooltip-trigger'}><p className={'tooltip dark large'}>{I18n.t(`users.${ArticleUtils.projectSuffix(article.project, 'no_highlighting')}`)}</p><a href={userLink} title={realName} target="_blank">{user.name}</a></div>;
        }

        return res;
      }));
    } else {
      setUserLinks(<div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>);
    }
  }, [users, status]);

  useEffect(() => {
    if (status === 'loading') {
      setUsersStatus(
        <div>
          <div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>
          <div className="user-legend authorship-status">{I18n.t('users.loading_authorship_data')}</div>
          <div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>
        </div>
      );
    } else if (status === 'failed') {
      setUsersStatus(<div className="user-legend authorship-status-failed">{I18n.t('users.authorship_data_not_fetched')}: {failureMessage}</div>);
    } else if (status === 'ready') {
      setUsersStatus('');
    }
  }, [status]);

  return (
    <div className="user-legend-wrap">
      <div className="user-legend">{I18n.t('users.edits_by')}&nbsp;</div>
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
