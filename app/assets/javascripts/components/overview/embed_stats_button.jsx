import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const EmbedStatsButton = createReactClass({
  displayName: 'EmbedStatsButton',

  propTypes: {
    title: PropTypes.string
  },

  getInitialState() {
    return { show: false, status: '' };
  },

  copyToClipboard(e) {
    const el = e.target;
    el.select();
    document.execCommand('copy');
    this.setState({ status: 'Copied!' });
  },

  show() {
    this.setState({ show: true });
  },

  hide() {
    this.setState({ show: false });
  },

  render() {
    if (!this.state.show) {
      return (<a onClick={this.show} className="button">{I18n.t('courses.embed_course_stats')}</a>);
    }

    const url = location.href.replace('courses', 'embed/course_stats');

    return (
      <div className="basic-modal course-stats-download-modal embed_stats">
        <button onClick={this.hide} className="pull-right article-viewer-button icon-close" />
        <h4>{I18n.t('courses.embed_course_stats_description')} <code>&lt;body&gt;</code></h4>
        <textarea
          id="embed"
          readOnly
          value={
`<a href="${location.href}">${this.props.title}</a><!-- This is optional -->
<iframe src="${url}" style="width:100%;border:0px none transparent;"></iframe>`}
          onClick={this.copyToClipboard}
        />
        <small>{this.state.status}</small>
      </div>
    );
  }
});

export default EmbedStatsButton;
