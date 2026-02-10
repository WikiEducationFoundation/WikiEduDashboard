import React, { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useNavigate, useLocation, useParams } from 'react-router-dom';
import Modal from '../../../components/common/modal.jsx';
import TextInput from '../../../components/common/text_input.jsx';
import TextAreaInput from '../../../components/common/text_area_input.jsx';
import { addModule } from '../../../actions/training_modification_actions.js';
import { setValid, setInvalid, activateValidations, resetValidations } from '../../../actions/validation_actions.js';
import { firstValidationErrorMessage } from '../../../selectors';

const AddModule = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const [module, setModule] = useState({
    name: '',
    slug: '',
    description: ''
  });
  const firstErrorMessage = useSelector(state => firstValidationErrorMessage(state));
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const location = useLocation();
  const { library_id, category_id } = useParams();
  const libraryPath = location.pathname.split('/').slice(0, 3).join('/');

  const handleInputChange = (key, value) => {
    setModule(prevModule => ({
      ...prevModule,
      [key]: value
    }));
  };

  useEffect(() => {
    dispatch(resetValidations());
  }, [props.editMode]);

  const validateFields = () => {
    let valid = true;
    const message = I18n.t('training.validation_message');
    if (!module.name.trim()) {
      dispatch(setInvalid('name', message));
      valid = false;
    } else {
      dispatch(setValid('name'));
    }

    if (!module.slug.trim()) {
      dispatch(setInvalid('slug', message));
      valid = false;
    } else {
      dispatch(setValid('slug'));
    }

    if (!module.description.trim()) {
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
      dispatch(addModule(library_id, category_id, module, setSubmitting));
    }
  };

  const handleCancelClick = () => {
    navigate(libraryPath);
  };

  let formStyle;
  if (submitting) {
    formStyle = { pointerEvents: 'none', opacity: '0.5' };
  }

  if (!props.editMode) {
    return null;
  }

  return (
    <div className="training-modification container lib-container">
      <Modal>
        <div className="container">
          <div className="wizard__panel active training_modal" style={formStyle}>
            <h3>{I18n.t('training.add_new_module')}</h3>
            <p>{I18n.t('training.add_module_msg')}</p>
            <div className="column">
              <TextInput
                id="name"
                onChange={handleInputChange}
                value={module.name}
                value_key="name"
                required
                editable
                label={I18n.t('training.module_name')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.module_name')}`}
              />
              <TextInput
                id="slug"
                onChange={handleInputChange}
                value={module.slug}
                value_key="slug"
                required
                editable
                label={I18n.t('training.module_slug')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.module_slug')}`}
              />
              <button className="button light" onClick={handleCancelClick}>{I18n.t('training.cancel')}</button>
              <span className="validation-error"> &nbsp; {firstErrorMessage || '\xa0'}</span>
            </div>
            <div className="column form-group">
              <TextAreaInput
                id="description"
                onChange={handleInputChange}
                value={module.description}
                value_key="description"
                required
                editable
                label={I18n.t('training.module_description')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.module_description')}`}
              />
              <button className="button dark right" onClick={submitHandler}>{I18n.t('training.add')}</button>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
};

export default AddModule;
