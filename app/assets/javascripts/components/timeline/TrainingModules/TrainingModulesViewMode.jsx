import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TrainingModules from '../TrainingModules/TrainingModules';
import {
    DISCUSSION_KIND, EXERCISE_KIND
  } from '../../../constants';

const TrainingModulesViewMode = createReactClass({
  displayName: 'TrainingModulesViewMode',

  propTypes: {
    block: PropTypes.object,
    all_training_modules: PropTypes.array,
    trainingLibrarySlug: PropTypes.string.isRequired,
    editable: PropTypes.bool,
    isStudent: PropTypes.bool
  },

  render() {
    const block = this.props.block;
    const modules = [];
    const length = block.training_modules.length;

    if (!length) { return null; }

    const partitioned = block.training_modules.reduce((acc, mod) => {
      let key = 'modules';
        if (mod.kind === EXERCISE_KIND) key = 'exercises';
        if (mod.kind === DISCUSSION_KIND) key = 'discussions';
      acc[key].push(mod);
      return acc;
    }, { discussions: [], exercises: [], modules: [] });

    if (partitioned.modules.length) {
      modules.push(<TrainingModules
        all_modules={this.props.all_training_modules}
        block_modules={partitioned.modules}
        block={block}
        editable={this.props.editable}
        header={length > 1 && 'Training'}
        key="training-modules"
        trainingLibrarySlug={this.props.trainingLibrarySlug}
        isStudent={this.props.isStudent}
      />);
    }

    if (partitioned.exercises.length) {
      modules.push(<TrainingModules
        all_modules={this.props.all_training_modules}
        block_modules={partitioned.exercises}
        block={block}
        editable={this.props.editable}
        header={length > 1 && 'Exercise'}
        key="assignment-modules"
        trainingLibrarySlug={this.props.trainingLibrarySlug}
        isStudent={this.props.isStudent}
      />);
    }

    if (partitioned.discussions.length) {
      modules.push(<TrainingModules
        all_modules={this.props.all_training_modules}
        block_modules={partitioned.discussions}
        block={block}
        editable={this.props.editable}
        header={length > 1 && 'Discussion'}
        key="discussion-modules"
        trainingLibrarySlug={this.props.trainingLibrarySlug}
        isStudent={this.props.isStudent}
      />);
    }

    return modules;
  }
});

export default TrainingModulesViewMode;
