import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import _ from 'lodash';
import selectStyles from '../../../styles/select';

// Components
import ModuleRow from './ModuleRow/ModuleRow';

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

    const modules = this.props.block_modules.map(module => (
      <ModuleRow
        key={module.id}
        module={module}
        trainingLibrarySlug={this.props.trainingLibrarySlug}
      />
    ));

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
