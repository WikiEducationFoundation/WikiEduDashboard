// Used by any component that requires "Edit", "Save", and "Cancel" buttons

import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { isValid } from '../../utils/validation_utils.js';

const mapStateToProps = state => ({
  validations: state.validation.validations,
});

const Editable = (Component, Stores, Save, GetState, Label, SaveLabel, SaveOnly) => {
  const editable = createReactClass({
    displayName: 'Editable',
    propTypes: {
      course_id: PropTypes.any,
      current_user: PropTypes.object,
      editable: PropTypes.bool
    },

    mixins: Stores.map(store => store.mixin),

    getInitialState() {
      const newState = GetState();
      newState.editable = this.state ? this.state.editable : false;
      return newState;
    },

    cancelChanges() {
      for (let i = 0; i < Stores.length; i++) {
        const store = Stores[i];
        store.restore();
      }
      return this.toggleEditable();
    },
    saveChanges() {
      if (isValid(this.props.validations)) {
        Save($.extend(true, {}, this.state), this.props.course_id);
        return this.toggleEditable();
      }
      return alert(I18n.t('error.form_errors'));
    },
    toggleEditable() {
      return this.setState({ editable: !this.state.editable });
    },
    storeDidChange() {
      return this.setState(GetState());
    },
    controls(extraControls, hideEdit = false, saveOnly = false) {
      const permissions = this.props.current_user.isNonstudent;

      if (permissions && this.state.editable) {
        let className;
        let cancel;
        if (!saveOnly) {
          className = 'controls';
          if (!SaveOnly) {
            cancel = (
              <button onClick={this.cancelChanges} className="button">{I18n.t('editable.cancel')}</button>
            );
          }
        }

        return (
          <div className={className}>
            {cancel}
            <button onClick={this.saveChanges} className="dark button">{SaveLabel || I18n.t('editable.save')}</button>
            {extraControls}
          </div>
        );
      } else if (permissions && (this.props.editable === undefined || this.props.editable)) {
        let edit;
        let editLabel = I18n.t('editable.edit');
        if (Label !== undefined) {
          editLabel = Label;
        }
        if (!hideEdit) {
          edit = <button onClick={this.toggleEditable} className="dark button">{editLabel}</button>;
        }
        return (
          <div className="controls">
            {edit}
            {extraControls}
          </div>
        );
      }
    },
    render() {
      return <Component {...this.props} {...this.state} disableSave={this.disableSave} controls={this.controls} />;
    }
  });

  return connect(mapStateToProps)(editable);
};

export default Editable;
