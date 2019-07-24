// Used by any component that requires "Edit", "Save", and "Cancel" buttons

import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { resetValidations } from '../../actions/validation_actions';
import { isValid, editPermissions } from '../../selectors';

const mapStateToProps = state => ({
  editPermissions: editPermissions(state),
  isValid: isValid(state)
});

const mapDispatchToProps = {
  resetValidations
};

const EditableRedux = (Component, Label) => {
  const editableComponent = createReactClass({
    displayName: 'EditableRedux',
    propTypes: {
      course_id: PropTypes.any,
      current_user: PropTypes.object,
      editable: PropTypes.bool,
      resetState: PropTypes.func,
      persistCourse: PropTypes.func.isRequired,
      nameHasChanged: PropTypes.func.isRequired,
      isValid: PropTypes.bool.isRequired,
      resetValidations: PropTypes.func.isRequired
    },

    getInitialState() {
      return { editable: this.state ? this.state.editable : false };
    },

    cancelChanges() {
      if (typeof (this.props.resetState) === 'function') {
        this.props.resetState();
      }
      this.props.resetValidations();
      return this.toggleEditable();
    },

    saveChanges() {
      // If there are validation problems, show error message
      if (!this.props.isValid) {
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
      if (!this.props.editPermissions) { return null; }

      if (this.state.editable) {
        return (
          <div className="controls">
            <button onClick={this.cancelChanges} className="button">{I18n.t('editable.cancel')}</button>
            <button onClick={this.saveChanges} className="dark button">{I18n.t('editable.save')}</button>
          </div>
        );
      } else if (this.props.editable === undefined || this.props.editable) {
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
  });
  return connect(mapStateToProps, mapDispatchToProps)(editableComponent);
};


export default EditableRedux;
