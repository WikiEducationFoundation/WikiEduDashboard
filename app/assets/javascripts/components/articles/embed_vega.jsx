import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Popover from '../common/popover.jsx';
import PopoverExpandable from '../high_order/popover_expandable.jsx';

const EmbedVega = createReactClass({
  displayName: 'EmbedVega',

  propTypes: {
    spec: PropTypes.object.isRequired,
    is_open: PropTypes.bool
  },

  getInitialState() {
    return { step1status: '', step2status: '' };
  },

  getKey() {
    return 'embed_button';
  },

  copyToClipboard(e) {
    const el = e.target;
    el.select();
    document.execCommand('copy');
    this.setState({ [`${el.id}status`]: 'Copied!' });
  },

  render() {
    const spec = JSON.stringify(this.props.spec);
    const steps = (
      <tr>
        <td>
          <h3>Step 1</h3>
          <p>Copy the following code into the <code>&lt;head&gt;</code> section.</p>
          <textarea
            id="step1"
            readOnly
            value={
`<script src="https://cdn.jsdelivr.net/npm/vega@4"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@3"></script>`
            }
            onClick={this.copyToClipboard}
          />
          <small>{this.state.step1status}</small>
          <br />
          <h3>Step 2</h3>
          <p>Copy the following code into the <code>&lt;body&gt;</code> section.</p>
          <textarea
            id="step2"
            readOnly
            value={
`<div id="wikiEmbed"></div> <!-- This is where the graph will be embedded -->
<script type="text/javascript">
  vegaEmbed("#wikiEmbed",${spec},{defaultStyle: true})
</script>`}
            onClick={this.copyToClipboard}
          />
          <small>{this.state.step2status}</small>
        </td>
      </tr>
    );

    return (
      <div className="pop__container embed_vega">
        <button onClick={this.props.open} className="button primary small">
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

export default PopoverExpandable(EmbedVega);
