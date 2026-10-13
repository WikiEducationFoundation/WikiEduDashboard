import React from 'react';
import { Link } from 'react-router-dom';
import PropTypes from 'prop-types';

const ProfileCard = ({ title, summary, link, iconClass, featured }) => {
  const cardClass = featured ? 'profile-card profile-card--featured' : 'profile-card';

  return (
    <div className={cardClass}>
      <div className="profile-card__header">
        {iconClass && <i className={`icon ${iconClass}`} />}
        <h4 className="profile-card__title">{title}</h4>
      </div>
      <div className="profile-card__body">
        {summary}
      </div>
      <div className="profile-card__footer">
        <Link to={link} className="button border ghost profile-card__button">
          {I18n.t('revisions.see_more')} →
        </Link>
      </div>
    </div>
  );
};

ProfileCard.propTypes = {
  title: PropTypes.string.isRequired,
  summary: PropTypes.node,
  link: PropTypes.string.isRequired,
  iconClass: PropTypes.string,
  featured: PropTypes.bool
};

export default ProfileCard;