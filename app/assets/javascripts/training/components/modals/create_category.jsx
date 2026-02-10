import React, { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useParams } from 'react-router-dom';
import Modal from '../../../components/common/modal.jsx';
import TextInput from '../../../components/common/text_input.jsx';
import TextAreaInput from '../../../components/common/text_area_input.jsx';
import { createCategory } from '../../../actions/training_modification_actions.js';
import { setValid, setInvalid, activateValidations, resetValidations } from '../../../actions/validation_actions.js';
import { firstValidationErrorMessage } from '../../../selectors';

const CreateCategory = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const [category, setCategory] = useState({
    title: '',
    description: ''
  });
  const firstErrorMessage = useSelector(state => firstValidationErrorMessage(state));
  const { library_id } = useParams();
  const dispatch = useDispatch();

  const handleInputChange = (key, value) => {
    setCategory(prevCategory => ({
      ...prevCategory,
      [key]: value
    }));
  };

  useEffect(() => {
    dispatch(resetValidations());
  }, []);

  const validateFields = () => {
    let valid = true;
    const message = I18n.t('training.validation_message');
    if (!category.title.trim()) {
      dispatch(setInvalid('title', message));
      valid = false;
    } else {
      dispatch(setValid('title'));
    }

    if (!category.description.trim()) {
      dispatch(setInvalid('description', message));
      valid = false;
    } else {
      dispatch(setValid('description'));
    }

    return valid;
  };

  const submitHandler = () => {
    dispatch(activateValidations());

    if (validateFields()) {
      setSubmitting(true);
      dispatch(createCategory(library_id, category, setSubmitting, props.toggleModal));
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
          <div className="wizard__panel active training_modal single_column small-container" style={formStyle}>
            <h3>{I18n.t('training.create_category')}</h3>
            <p>{I18n.t('training.create_category_msg')}</p>
            <div>
              <TextInput
                id="title"
                onChange={handleInputChange}
                value={category.title}
                value_key="title"
                required
                editable
                label={I18n.t('training.category_title')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.category_title')}`}
              />
              <TextAreaInput
                id="description"
                onChange={handleInputChange}
                value={category.description}
                value_key="description"
                required
                editable
                label={I18n.t('training.category_description')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.category_description')}`}
              />
              <button className="button light" onClick={props.toggleModal}>{I18n.t('training.cancel')}</button>
              <span className="validation-error"> &nbsp; {firstErrorMessage || '\xa0'}</span>
              <button className="button dark right" onClick={submitHandler}>{I18n.t('training.create')}</button>
            </div>
          </div>
        </div>
      </Modal>
    </>
  );
};

export default CreateCategory;
