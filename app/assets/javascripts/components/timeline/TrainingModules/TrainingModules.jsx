import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select, { components } from 'react-select';
import { filter, compact } from 'lodash-es';
import selectStyles from '../../../styles/select';

// Components
import ModuleRow from './ModuleRow/ModuleRow';
import { EXERCISE_KIND, DISCUSSION_KIND } from '../../../constants';

const TrainingModules = createReactClass({
  displayName: 'TrainingModules',

  propTypes: {
    all_modules: PropTypes.array,
    block_modules: PropTypes.array,
    editable: PropTypes.bool,
    header: PropTypes.any,
    isStudent: PropTypes.bool,
    onChange: PropTypes.func,
    trainingLibrarySlug: PropTypes.string.isRequired,
  },

  getInitialState() {
    let selections;
    if (this.props.block_modules) {
      selections = this.props.block_modules.map(module => ({ value: module.id, label: module.name + this.moduleLabel(module.kind) }));
    }
    return { value: selections };
  },

  onChange(selections) {
    let trainingModuleIds = [];
    if (selections) {
      trainingModuleIds = selections.map(trainingModule => trainingModule.value);
    }
    this.setState({ value: selections });
    return this.props.onChange(trainingModuleIds);
  },

  moduleLabel(kind) {
    if (kind === EXERCISE_KIND) {
      return ` (${I18n.t('training.kind.exercise')})`;
    }
    if (kind === DISCUSSION_KIND) {
      return ` (${I18n.t('training.kind.discussion')})`;
    }
    return ` (${I18n.t('training.kind.training')})`;
  },

  trainingSelector() {
    const MultiValueRemove = (props) => {
      return (
        <components.MultiValueRemove {...props}>
          <components.CrossIcon aria-hidden={false} aria-label={'Remove Module'} />
        </components.MultiValueRemove>
      );
    };
    const options = filter(compact(this.props.all_modules), module => module.status !== 'deprecated')
      .map(module => ({ value: module.id, label: module.name + this.moduleLabel(module.kind) }));
    return (
      <div className="block__training-modules">
        <div>
          <h4>Training modules</h4>
          <Select
            components={{ MultiValueRemove }}
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

    const modules = this.props.block_modules.map(module => (
      <ModuleRow
        key={module.id}
        isStudent={this.props.isStudent}
        module={module}
        trainingLibrarySlug={this.props.trainingLibrarySlug}
      />
    ));

    if (!modules.length) { return null; }

    const header = this.props.header || 'Training';
    const headerId = header.toLowerCase().split(/[^a-z]/).join('-');
    return (
      <div className="block__training-modules">
        <div>
          {this.props.header ? <h4 id={headerId}>{header}</h4> : null}
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
