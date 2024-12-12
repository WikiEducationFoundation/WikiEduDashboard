import React, { useState } from 'react';
import PropTypes from 'prop-types';

const CourseStatsDownloadModal = ({ course }) => {
  const [show, setShow] = useState(false);

  const showStats = () => {
    setShow(true);
  };

  const hideStats = () => {
    setShow(false);
  };

  if (!show) {
    return <button onClick={showStats} className="button">{I18n.t('courses.download_stats_data')}</button>;
  }

  const overviewCsvLink = `/course_csv?course=${course.slug}`;
  const uploadsCsvLink = `/course_uploads_csv?course=${course.slug}`;
  const studentsCsvLink = `/course_students_csv?course=${course.slug}`;
  const articlesCsvLink = `/course_articles_csv?course=${course.slug}`;
  const revisionsCsvLink = `/course_revisions_csv?course=${course.slug}`;
  const wikidataCsvLink = `/course_wikidata_csv?course=${course.slug}`;

  let wikidataLink;
  if (course.course_stats && course.home_wiki.project === 'wikidata') {
    wikidataLink = (
      <>
        <hr />
        <p>
          <a href={wikidataCsvLink} className="button right">{I18n.t('courses.data_wikidata')}</a>
          {I18n.t('courses.data_wikidata_info')}
        </p>
      </>
    );
  }

  return (
    <div className="basic-modal course-stats-download-modal">
      <button onClick={hideStats} className="pull-right article-viewer-button icon-close" />
      <h2>{I18n.t('courses.data_download_info')}</h2>
      <hr />
      <p>
        <a href={overviewCsvLink} className="button right">{I18n.t('courses.data_overview')}</a>
        {I18n.t('courses.data_overview_info')}
      </p>
      <hr />
      <p>
        <a href={uploadsCsvLink} className="button right">{I18n.t('courses.data_uploads')}</a>
        {I18n.t('courses.data_uploads_info')}
      </p>
      <hr />
      <p>
        <a href={studentsCsvLink} className="button right">{I18n.t('courses.data_students')}</a>
        {I18n.t('courses.data_students_info')}
      </p>
      <hr />
      <p>
        <a href={articlesCsvLink} className="button right">{I18n.t('courses.data_articles')}</a>
        {I18n.t('courses.data_articles_info')}
      </p>
      <hr />
      <p>
        <a href={revisionsCsvLink} className="button right">{I18n.t('courses.data_revisions')}</a>
        {I18n.t('courses.data_revisions_info')}
      </p>
      {wikidataLink}
    </div>
  );
};

CourseStatsDownloadModal.propTypes = {
  course: PropTypes.object.isRequired
};

export default CourseStatsDownloadModal;
