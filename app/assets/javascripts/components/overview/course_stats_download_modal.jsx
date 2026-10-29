import React from 'react';
import PropTypes from 'prop-types';
import useCourseDownloadModal from '../../hooks/useCourseDownloadModal.js';

const CourseStatsDownloadModal = ({ course }) => {
  const {
    show,
    openModal,
    closeModal,
    handleDownload,
    userSignedIn
  } = useCourseDownloadModal({ courseTitle: course.title || course.slug });

  const downloadOptions = [
    {
      id: `${course.slug}-overview`,
      href: `/course_csv?course=${course.slug}`,
      dataLabel: I18n.t('courses.data_overview'),
      info: I18n.t('courses.data_overview_info')
    },
    {
      id: `${course.slug}-uploads`,
      href: `/course_uploads_csv?course=${course.slug}`,
      dataLabel: I18n.t('courses.data_uploads'),
      info: I18n.t('courses.data_uploads_info')
    },
    {
      id: `${course.slug}-students`,
      href: `/course_students_csv?course=${course.slug}`,
      dataLabel: I18n.t('courses.data_students'),
      info: I18n.t('courses.data_students_info')
    },
    {
      id: `${course.slug}-articles`,
      href: `/course_articles_csv?course=${course.slug}`,
      dataLabel: I18n.t('courses.data_articles'),
      info: I18n.t('courses.data_articles_info')
    }
  ];

  if (course.course_stats && course.home_wiki?.project === 'wikidata') {
    downloadOptions.push({
      id: `${course.slug}-wikidata`,
      href: `/course_wikidata_csv?course=${course.slug}`,
      dataLabel: I18n.t('courses.data_wikidata'),
      info: I18n.t('courses.data_wikidata_info')
    });
  }

  if (!show) {
    return <button onClick={openModal} className="button">{I18n.t('courses.download_stats_data')}</button>;
  }

  let warning;
  if (!course.timeslice_update_ran) {
    warning = <div className="warning">{I18n.t('courses.data_download_warning')}</div>;
  }

  return (
    <div className="basic-modal course-stats-download-modal">
      <button onClick={closeModal} className="pull-right article-viewer-button icon-close" />
      <h2>{I18n.t('courses.data_download_info')}</h2>
      {warning}
      <hr />
      {downloadOptions.map((option, index) => (
        <React.Fragment key={option.id}>
          {index > 0 && <hr />}
          <p>
            {userSignedIn ? (
              <button
                type="button"
                onClick={e => handleDownload(option, e)}
                className="button right"
              >
                {option.dataLabel}
              </button>
            ) : (
              <a
                href={option.href}
                className="button right"
              >
                {option.dataLabel}
              </a>
            )}
            {option.info}
          </p>
        </React.Fragment>
      ))}
    </div>
  );
};

CourseStatsDownloadModal.propTypes = {
  course: PropTypes.object.isRequired
};

export default CourseStatsDownloadModal;
