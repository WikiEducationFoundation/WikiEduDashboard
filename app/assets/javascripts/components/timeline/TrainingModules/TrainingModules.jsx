import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import _ from 'lodash';
import {
  DISCUSSION_KIND, EXERCISE_KIND, TRAINING_MODULE_KIND
} from '../../../constants';

// Components
import ModuleStatus from './ModuleStatus/ModuleStatus';
import ModuleLink from './ModuleLink';
import ModuleName from './ModuleName';

import selectStyles from '../../../styles/select';

const TrainingModules = createReactClass({
  displayName: 'TrainingModules',

  propTypes: {
    block_modules: PropTypes.array,
    editable: PropTypes.bool,
    all_modules: PropTypes.array,
    onChange: PropTypes.func,
    trainingLibrarySlug: PropTypes.string.isRequired,
    header: PropTypes.any
  },

  getInitialState() {
    let selections;
    if (this.props.block_modules) {
      selections = this.props.block_modules.map(module => ({ value: module.id, label: module.name }));
    }
    return { value: selections };
  },

  onChange(selections) {
    const trainingModuleIds = selections.map(trainingModule => trainingModule.value);
    this.setState({ value: selections });
    return this.props.onChange(trainingModuleIds);
  },

  progressClass(progress) {
    const linkStart = 'timeline-module__';
    if (progress === 'Complete') {
      return `${linkStart}progress-complete `;
    }
    return `${linkStart}in-progress `;
  },

  trainingSelector() {
    const options = _.filter(_.compact(this.props.all_modules), module => module.status !== 'deprecated')
                    .map(module => ({ value: module.id, label: module.name }));
    return (
      <div className="block__training-modules">
        <div>
          <h4>Training modules</h4>
          <Select
            isMulti={true}
            name="block-training-modules"
            value={this.state.value}
            options={options}
            onChange={this.onChange}
            placeholder="Add training module(s)…"
            styles={selectStyles}
          />
        </div>
      </div>
    );
  },

  render() {
    if (this.props.editable) {
      return this.trainingSelector();
    }

    const modules = this.props.block_modules.map((module) => {
      const isTrainingModule = module.kind === TRAINING_MODULE_KIND;
      const isExercise = module.kind === EXERCISE_KIND;
      const isDiscussion = module.kind === DISCUSSION_KIND;

      let iconClassName = 'icon ';
      let progressClass;
      let linkText;

      if (isExercise || isDiscussion) {
        progressClass = this.progressClass(module.module_progress);
        linkText = 'View';
        iconClassName += 'icon-rt_arrow';
      } else if (isTrainingModule && module.module_progress) {
        progressClass = this.progressClass(module.module_progress);
        linkText = module.module_progress === 'Complete' ? 'View' : 'Continue';
        iconClassName += module.module_progress === 'Complete' ? 'icon-check' : 'icon-rt_arrow';
      } else {
        linkText = 'Start';
        iconClassName += 'icon-rt_arrow';
      }

      progressClass += ' block__training-modules-table__module-progress ';
      if (module.overdue === true) progressClass += ' overdue';
      if (module.deadline_status === 'complete') progressClass += ' complete';

      const link = `/training/${this.props.trainingLibrarySlug}/${module.slug}`;
      return (
        <tr key={module.id} className="training-module">
          <ModuleName {...module} isExercise={isExercise} />
          <ModuleStatus {...module} progressClass={progressClass} />
          <ModuleLink
            iconClassName={iconClassName}
            link={link}
            linkText={linkText}
            module_progress={module.module_progress}
          />
        </tr>
      );
    });

    const header = this.props.header || 'Training';
    const headerId = header.toLowerCase().split(/[^a-z]/).join('-');
    return (
      <div className="block__training-modules">
        <div>
          { this.props.header ? <h4 id={headerId}>{ header }</h4> : null }
          <table className="table table--small">
            <tbody>
              {modules}
            </tbody>
          </table>
        </div>
      </div>
    );
  }
});

export default TrainingModules;
