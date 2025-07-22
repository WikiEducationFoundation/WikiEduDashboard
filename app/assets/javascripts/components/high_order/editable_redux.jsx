// Used by any component that requires "Edit", "Save", and "Cancel" buttons

import React, { useState, useCallback } from 'react';
import { connect } from 'react-redux';
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
  const EditableWrapper = (props) => {
    const [editable, setEditable] = useState(false);

    const cancelChanges = useCallback(() => {
      if (typeof props.resetState === 'function') {
        props.resetState();
      }
      props.resetValidations();
      toggleEditable();
    }, [props.resetState, props.resetValidations]);

    const saveChanges = useCallback(() => {
      // If there are validation problems, show error message
      if (!props.isValid) {
        return alert(I18n.t('error.form_errors'));
      }

      // If the course slug has not changed, persist the data and exit edit mode
      if (!props.nameHasChanged()) {
        props.persistCourse(props.course_id);
        return toggleEditable();
      }

      // If the course has been renamed, we first warn the user that this is happening.
      if (confirm(I18n.t('editable.rename_confirmation'))) {
        return props.persistCourse(props.course_id, true);
      }
      return cancelChanges();
    }, [props.isValid, props.nameHasChanged, props.persistCourse, props.course_id, cancelChanges]);

    const toggleEditable = useCallback(() => {
      setEditable(prev => !prev);
    }, []);

    const controls = useCallback(() => {
      if (!props.editPermissions) { return null; }

      if (editable) {
        return (
          <div className="controls">
            <button onClick={cancelChanges} className="button">{I18n.t('editable.cancel')}</button>
            <button onClick={saveChanges} className="dark button">{I18n.t('editable.save')}</button>
          </div>
        );
      } else if (props.editable === undefined || props.editable) {
        return (
          <div className="controls">
            <button onClick={toggleEditable} className="dark button">{Label}</button>
          </div>
        );
      }
    }, [props.editPermissions, editable, props.editable, cancelChanges, saveChanges, toggleEditable]);

    return <Component {...props} editable={editable} controls={controls} />;
  };

  EditableWrapper.displayName = 'EditableRedux';

  EditableWrapper.propTypes = {
    course_id: PropTypes.any,
    current_user: PropTypes.object,
    editable: PropTypes.bool,
    resetState: PropTypes.func,
    persistCourse: PropTypes.func.isRequired,
    nameHasChanged: PropTypes.func.isRequired,
    isValid: PropTypes.bool.isRequired,
    resetValidations: PropTypes.func.isRequired,
    editPermissions: PropTypes.bool
  };

  return connect(mapStateToProps, mapDispatchToProps)(EditableWrapper);
};

export default EditableRedux;
