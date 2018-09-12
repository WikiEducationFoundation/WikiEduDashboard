import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';
import EditableRedux from '../high_order/editable_redux';

import Gradeable from './gradeable.jsx';

const Grading = createReactClass({
  displayName: 'Grading',

  propTypes: {
    weeks: PropTypes.array,
    blocks: PropTypes.array,
    editable: PropTypes.bool,
    controls: PropTypes.func,
    current_user: PropTypes.object.isRequired
  },

  render() {
    const gradeableBlocks = [];
    // The weeks prop has the order of the weeks, and the blocks within it.
    // However, the blocks within the weeks prop are not updated except when
    // the timeline is received from the server.
    // So to re-render when block details are changed, we need to use the weeks
    // prop to determine the order, but use the blocks prop to actually build
    // the rendered elements.
    // FIXME: when the Timeline gets converted to Redux, we can handle this kind
    // of thing in the reducers and/or via selectors.
    this.props.weeks.forEach(week => {
      week.blocks.forEach(block => {
        if (!block.points) { return; }
        const blocksPropBlock = this.props.blocks.find(propsBlock => block.id === propsBlock.id);
        // Handle blocks that got deleted.
        if (!blocksPropBlock) { return; }
        blocksPropBlock.grading_order = `${week.order}${block.order}`;
        gradeableBlocks.push(blocksPropBlock);
      });
    });

    if (!gradeableBlocks.length) {
      return <div />;
    }

    gradeableBlocks.sort((a, b) => {
      if (!a.grading_order || !b.grading_order) { return 1; }
      return a.grading_order - b.grading_order;
    });

    const total = _.sumBy(gradeableBlocks, 'points');

    const gradeables = gradeableBlocks.map((block) => {
      return (
        <Gradeable
          key={block.id}
          block={block}
          editable={this.props.editable}
        />
      );
    });

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

export default EditableRedux(Grading, I18n.t('editable.edit'));
