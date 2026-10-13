import React from 'react';
import ProfileCard from './profile_card';
import PropTypes from 'prop-types';

const ProfileDashboard = ({ stats, courses, uploads, trainingModules, username }) => {
  const studentStats = stats.as_student || {};
  const courseCount = courses?.length || 0;
  const uploadCount = uploads?.length || 0;
  const trainingModulesList = trainingModules || [];
  const completedTraining = trainingModulesList.filter(m => m.status === 'complete').length;
  const trainingTotal = trainingModulesList.length;

  return (
    <div className="profile-dashboard profile-dashboard--single-card">
      <ProfileCard
        featured={true}
        title={I18n.t('users.contribution_statistics')}
        iconClass="icon-stats"
        summary={
          <div className="profile-card__summary">
            <div className="profile-card__stats-grid profile-card__stats-grid--single-card">
              <div className="profile-card__stat">
                <span className="profile-card__label">{I18n.t('metrics.word_count')}</span>
                <span className="profile-card__value">{studentStats.individual_word_count || 0}</span>
              </div>
              <div className="profile-card__stat">
                <span className="profile-card__label">{I18n.t('metrics.references_count')}</span>
                <span className="profile-card__value">{studentStats.individual_references_count || 0}</span>
              </div>
              <div className="profile-card__stat">
                <span className="profile-card__label">{I18n.t('metrics.articles_edited')}</span>
                <span className="profile-card__value">{studentStats.individual_article_count || 0}</span>
              </div>
              <div className="profile-card__stat">
                <span className="profile-card__label">{I18n.t('courses.courses_enrolled')}</span>
                <span className="profile-card__value">{courseCount}</span>
              </div>
              <div className="profile-card__stat">
                <span className="profile-card__label">{I18n.t('uploads.label')}</span>
                <span className="profile-card__value">{uploadCount}</span>
              </div>
              {trainingTotal > 0 && (
                <div className="profile-card__stat">
                  <span className="profile-card__label">{I18n.t('users.training_module_status')}</span>
                  <span className="profile-card__value">{completedTraining} / {trainingTotal}</span>
                </div>
              )}
            </div>
          </div>
        }
        link={`/users/${username}`}
      />
    </div>
  );
};

ProfileDashboard.propTypes = {
  stats: PropTypes.object,
  courses: PropTypes.array,
  uploads: PropTypes.array,
  trainingModules: PropTypes.array,
  username: PropTypes.string.isRequired
};

export default ProfileDashboard;