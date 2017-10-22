import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const CourseStatsDownloadModal = createReactClass({
  displayName: 'CourseStatsDownloadModal',

  propTypes: {
    course: PropTypes.object
  },

  getInitialState() {
    return { show: false };
  },

  show() {
    this.setState({ show: true });
  },

  hide() {
    this.setState({ show: false });
  },

  render() {
    if (!this.state.show) {
      return (<a onClick={this.show} className="button">{I18n.t('courses.download_stats_data')}</a>);
    }

    const overviewCsvLink = `/course_csv?course=${this.props.course.slug}`;
    const editsCsvLink = `/course_edits_csv?course=${this.props.course.slug}`;
    const uploadsCsvLink = `/course_uploads_csv?course=${this.props.course.slug}`;
    const studentsCsvLink = `/course_students_csv?course=${this.props.course.slug}`;
    const articlesCsvLink = `/course_articles_csv?course=${this.props.course.slug}`;

    return (
      <div className="basic-modal course-stats-download-modal">
        <button onClick={this.hide} className="pull-right article-viewer-button icon-close" />
        <h2>{I18n.t('courses.data_download_info')}</h2>
        <hr />
        <p>
          <a href={overviewCsvLink} className="button right">{I18n.t('courses.data_overview')}</a>
          {I18n.t('courses.data_overview_info')}
        </p>
        <hr />
        <p>
          <a href={editsCsvLink} className="button right">{I18n.t('courses.data_edits')}</a>
          {I18n.t('courses.data_edits_info')}
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
      </div>
    );
  }
});

export default CourseStatsDownloadModal;
