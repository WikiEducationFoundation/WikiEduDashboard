import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextInput from '../common/text_input.jsx';
import GradeableActions from '../../actions/gradeable_actions.js';

const Gradeable = createReactClass({
  displayName: 'Gradeable',

  propTypes: {
    block: PropTypes.object,
    gradeable: PropTypes.object,
    total: PropTypes.number,
    editable: PropTypes.bool
  },

  updateGradeable(valueKey, value) {
    const toPass = $.extend(true, {}, this.props.gradeable);
    toPass[valueKey] = value;
    return GradeableActions.updateGradeable(toPass);
  },

  render() {
    const { block } = this.props;
    if (!block) {
      return <div />;
    }
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
          value={this.props.gradeable.points.toString()}
          value_key={'points'}
          editable={this.props.editable}
          label={I18n.t('timeline.gradeable_value')}
          append="%"
        />
      </li>
    );
  }
}
);

export default Gradeable;
