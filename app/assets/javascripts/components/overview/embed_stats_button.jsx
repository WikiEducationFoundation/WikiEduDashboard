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
    const url = `${location.href}/stats`;
    const steps = (
      <tr>
        <td>
          <h3>To embed the Course Stats:</h3>
          <p>Copy the following code into the <code>&lt;body&gt;</code> section.</p>
          <textarea
            id="embed"
            readOnly
            value={
`<iframe src="${url}" style="width:100%;border:0px none transparent;"></iframe>`}
            onClick={this.copyToClipboard}
          />
          <small>{this.state.status}</small>
        </td>
      </tr>
    );

    return (
      <div className="pop__container embed_stats">
        <button onClick={this.props.open} className="button small">
          Embed&nbsp;&lt;/&gt;
        </button>
        <Popover
          is_open={this.props.is_open}
          rows={steps}
        />
      </div>
    );
  }
});

export default PopoverExpandable(EmbedStatsButton);
