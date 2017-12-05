import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import Gradeable from './gradeable.jsx';
import BlockStore from '../../stores/block_store.js';

const Grading = createReactClass({
  displayName: 'Grading',

  propTypes: {
    gradeables: PropTypes.array,
    editable: PropTypes.bool,
    controls: PropTypes.func
  },

  render() {
    // TODO: Change _.sum to _.sumBy when lodash is upgraded to v4.
    const total = _.sum(this.props.gradeables, 'points');
    const gradeables = this.props.gradeables.map((gradeable) => {
      const block = BlockStore.getBlock(gradeable.gradeable_item_id);
      return (
        <Gradeable
          gradeable={gradeable}
          block={block}
          key={gradeable.id}
          editable={this.props.editable}
          total={total}
        />
      );
    });
    gradeables.sort((a, b) => {
      if (!a.props.gradeable || !b.props.gradeable) { return 1; }
      return a.props.gradeable.order - b.props.gradeable.order;
    });
    let noGradeables;
    if (!gradeables.length) {
      noGradeables = (
        <li className="row view-all">
          <div><p>{I18n.t('timeline.gradeables_none')}</p></div>
        </li>
      );
    }

    return (
      <div className="grading__grading-container">
        <a name="grading" />
        <div className="section-header timeline__grading-container">
          <h3>{I18n.t('timeline.grading_header', { total })}</h3>
          {this.props.controls(null, this.props.gradeables.length < 1)}
        </div>
        <ul className="list-unstyled timeline__grading-container">
          {gradeables}
          {noGradeables}
        </ul>
      </div>
    );
  }
}
);

export default Grading;
