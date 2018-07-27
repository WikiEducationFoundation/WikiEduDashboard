// Used by any component that requires "Edit", "Save", and "Cancel" buttons

import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import ValidationStore from '../../stores/validation_store.js';

const EditableRedux = (Component, Label) =>
  createReactClass({
    displayName: 'EditableRedux',
    propTypes: {
      course_id: PropTypes.any,
      current_user: PropTypes.object,
      editable: PropTypes.bool,
      resetState: PropTypes.func.isRequired,
      persistCourse: PropTypes.func.isRequired,
      nameHasChanged: PropTypes.func.isRequired
    },

    getInitialState() {
      return { editable: this.state ? this.state.editable : false };
    },

    cancelChanges() {
      this.props.resetState();
      ValidationStore.reset();
      return this.toggleEditable();
    },

    saveChanges() {
      // If there are validation problems, show error message
      if (!ValidationStore.isValid()) {
        return alert(I18n.t('error.form_errors'));
      }

      // If the course slug has not changed, persist the data and exit edit mode
      if (!this.props.nameHasChanged()) {
        this.props.persistCourse(this.props.course_id);
        return this.toggleEditable();
      }

      // If the course has been renamed, we first warn the user that this is happening.
      if (confirm(I18n.t('editable.rename_confirmation'))) {
        return this.props.persistCourse(this.props.course_id, true);
      }
      return this.cancelChanges();
    },

    toggleEditable() {
      return this.setState({ editable: !this.state.editable });
    },

    controls() {
      const permissions = this.props.current_user.isNonstudent;
      if (!permissions) { return null; }

      if (this.state.editable) {
        return (
          <div className="controls">
            <button onClick={this.cancelChanges} className="button">{I18n.t('editable.cancel')}</button>
            <button onClick={this.saveChanges} className="dark button">{I18n.t('editable.save')}</button>
          </div>
        );
      } else if (permissions && (this.props.editable === undefined || this.props.editable)) {
        return (
          <div className="controls">
            <button onClick={this.toggleEditable} className="dark button">{Label}</button>
          </div>
        );
      }
    },

    render() {
      return <Component {...this.props} {...this.state} disableSave={this.disableSave} controls={this.controls} />;
    }
  }
  )
;

export default EditableRedux;
