import React from 'react';

const CourseStatsDownloadModal = React.createClass({
  displayName: 'CourseStatsDownloadModal',

  propTypes: {
    course: React.PropTypes.object
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
        <button onClick={this.hide} className="pull-right article-viewer-button icon-close"></button>
        <p>{I18n.t('courses.data_download_info')}</p>
        <p><a href={overviewCsvLink} className="button">{I18n.t('courses.data_overview')}</a></p>
        <p><a href={editsCsvLink} className="button">{I18n.t('courses.data_edits')}</a></p>
        <p><a href={uploadsCsvLink} className="button">{I18n.t('courses.data_uploads')}</a></p>
        <p><a href={studentsCsvLink} className="button">{I18n.t('courses.data_students')}</a></p>
        <p><a href={articlesCsvLink} className="button">{I18n.t('courses.data_articles')}</a></p>
      </div>
    );
  }
});

export default CourseStatsDownloadModal;
