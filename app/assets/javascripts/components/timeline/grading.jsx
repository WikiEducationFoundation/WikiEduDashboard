import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import Gradeable from './gradeable.jsx';

const Grading = createReactClass({
  displayName: 'Grading',

  propTypes: {
    blocks: PropTypes.array,
    editable: PropTypes.bool,
    controls: PropTypes.func
  },

  render() {
    const total = _.sumBy(this.props.blocks, 'points');
    const gradeableBlocks = this.props.blocks.filter(block => block.points);
    const gradeables = gradeableBlocks.map((block) => {
      return (
        <Gradeable
          key={block.id}
          block={block}
          editable={this.props.editable}
        />
      );
    });

    if (!gradeables.length) {
      return <div />;
    }

    return (
      <div className="grading__grading-container">
        <a name="grading" />
        <div className="section-header timeline__grading-container">
          <h3>{I18n.t('timeline.grading_header', { total })}</h3>
          {this.props.controls(null, gradeables.length < 1)}
        </div>
        <ul className="list-unstyled timeline__grading-container">
          {gradeables}
        </ul>
      </div>
    );
  }
}
);

export default Grading;
