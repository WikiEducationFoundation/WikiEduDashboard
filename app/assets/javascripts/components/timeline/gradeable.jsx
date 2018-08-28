import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextInput from '../common/text_input.jsx';
import BlockActions from '../../actions/block_actions.js';

const Gradeable = createReactClass({
  displayName: 'Gradeable',

  propTypes: {
    block: PropTypes.object,
    editable: PropTypes.bool
  },

  updateGradeable(valueKey, value) {
    const toPass = $.extend(true, {}, this.props.block);
    toPass[valueKey] = parseInt(value);
    return BlockActions.updateBlock(toPass);
  },

  render() {
    const { block } = this.props;
    const title = block.title;

    let className = 'block-title';
    if (this.props.editable) {
      className += ' block-title--editing';
    }

    return (
      <li className="gradeable block">
        <h4 className={className}>
          {title}
        </h4>
        <TextInput
          onChange={this.updateGradeable}
          value={this.props.block.points.toString()}
          value_key={'points'}
          editable={this.props.editable}
          label={I18n.t('timeline.gradeable_value')}
        />
      </li>
    );
  }
}
);

export default Gradeable;
