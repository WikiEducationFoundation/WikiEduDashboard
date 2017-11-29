import React from 'react';
import PropTypes from 'prop-types';
import UserUtils from '../../utils/user_utils.js';

const ArticleViewerLegend = ({ article, users, colors, status }) => {
  let userLinks;
  if (users) {
    userLinks = users.map((user, i) => {
      const userLink = UserUtils.userTalkUrl(user.name, article.language, article.project);
      return (
        <div key={`legend-${user.name}`} className={`user-legend ${colors[i]}`}>
          <a href={userLink} target="_blank">{user.name}</a>
        </div>
      );
    });
  } else {
    userLinks = <div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>;
  }

  let usersStatus;
  if (status === 'loading') {
    usersStatus = (
      <div>
        <div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>
        <div className="user-legend authorship-status">loading authorship data</div>
        <div className="user-legend authorship-loading"> &nbsp; &nbsp; </div>
      </div>
    );
  } else if (status === 'failed') {
    usersStatus = <div className="user-legend authorship-status-failed">could not fetch authorship data</div>;
  }

  return (
    <div className="user-legend-wrap">
      <div className="user-legend">Edits by: </div>
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

export default ArticleViewerLegend;
