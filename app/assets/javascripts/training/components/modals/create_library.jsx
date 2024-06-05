import React, { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Modal from '../../../components/common/modal.jsx';
import TextInput from '../../../components/common/text_input.jsx';
import TextAreaInput from '../../../components/common/text_area_input.jsx';
import { createLibrary } from '../../../actions/training_modification_actions.js';
import { setValid, setInvalid, activateValidations, resetValidations } from '../../../actions/validation_actions.js';
import { firstValidationErrorMessage } from '../../../selectors';

const CreateLibrary = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const [library, setLibrary] = useState({
    name: '',
    slug: '',
    introduction: ''
  });
  const firstErrorMessage = useSelector(state => firstValidationErrorMessage(state));
  const dispatch = useDispatch();

  const handleInputChange = (key, value) => {
    setLibrary(prevLibrary => ({
      ...prevLibrary,
      [key]: value
    }));
  };

  useEffect(() => {
    dispatch(resetValidations());
  }, []);

  const validateFields = () => {
    let valid = true;
    const message = I18n.t('training.validation_message');
    if (!library.name.trim()) {
      dispatch(setInvalid('name', message));
      valid = false;
    } else {
      dispatch(setValid('name'));
    }

    if (!library.slug.trim()) {
      dispatch(setInvalid('slug', message));
      valid = false;
    } else {
      dispatch(setValid('slug'));
    }

    if (!library.introduction.trim()) {
      dispatch(setInvalid('introduction', message));
      valid = false;
    } else {
      dispatch(setValid('introduction'));
    }

    return valid;
  };

  const submitHandler = () => {
    dispatch(activateValidations());

    if (validateFields()) {
      setSubmitting(true);
      dispatch(createLibrary(library, setSubmitting, props.modalHandler));
    }
  };

  let formStyle;
  if (submitting) {
    formStyle = { pointerEvents: 'none', opacity: '0.5' };
  }

  return (
    <>
      <Modal>
        <div className="container">
          <div className="wizard__panel active training_modal" style={formStyle}>
            <h3>{I18n.t('training.create_library')}</h3>
            <p>{I18n.t('training.create_library_msg')}</p>
            <div className="column">
              <TextInput
                id="name"
                onChange={handleInputChange}
                value={library.name}
                value_key="name"
                required
                editable
                label={I18n.t('training.library_name')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.library_name')}`}
              />
              <TextInput
                id="slug"
                onChange={handleInputChange}
                value={library.slug}
                value_key="slug"
                required
                editable
                label={I18n.t('training.library_slug')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.library_slug')}`}
              />
              <button className="button light" onClick={props.modalHandler}>{I18n.t('training.cancel')}</button>
              <span className="validation-error"> &nbsp; {firstErrorMessage || '\xa0'}</span>
            </div>
            <div className="column form-group">
              <TextAreaInput
                id="introduction"
                onChange={handleInputChange}
                value={library.introduction}
                value_key="introduction"
                required
                editable
                label={I18n.t('training.library_introduction')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.library_introduction')}`}
              />
              <button className="button dark right" onClick={submitHandler}>{I18n.t('training.create')}</button>
            </div>
          </div>
        </div>
      </Modal>
    </>
  );
};

export default CreateLibrary;
