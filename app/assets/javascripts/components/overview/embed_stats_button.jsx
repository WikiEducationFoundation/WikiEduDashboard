import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';

const EmbedStatsButton = createReactClass({
  displayName: 'EmbedCourseStats',

  propTypes: {
    is_open: PropTypes.bool
  },

  getInitialState() {
    return { status: '' };
  },

  getKey() {
    return 'embed_button';
  },

  copyToClipboard(e) {
    const el = e.target;
    el.select();
    document.execCommand('copy');
    this.setState({ status: 'Copied!' });
  },

  render() {
    const url = `${location.protocol}//${location.host}/stats${location.pathname}`;
    const steps = (
      <tr>
        <td>
          <h3>{I18n.t('courses.embed_course_stats_heading')}:</h3>
          <p>{I18n.t('courses.embed_course_stats_description')} <code>&lt;body&gt;</code></p>
          <textarea
            id="embed"
            readOnly
            value={
`<a href=${location.href}>${this.props.title}</a><!-- This is optional -->
<iframe src="${url}" style="width:100%;border:0px none transparent;"></iframe>`}
            onClick={this.copyToClipboard}
          />
          <small>{this.state.status}</small>
        </td>
      </tr>
    );

    return (
      <div className="pop__container embed_stats">
        <a onClick={this.props.open} className="button">
          Embed Course Stats&nbsp;&lt;/&gt;
        </a>
        <Popover
          is_open={this.props.is_open}
          rows={steps}
        />
      </div>
    );
  }
});

export default PopoverExpandable(EmbedStatsButton);
