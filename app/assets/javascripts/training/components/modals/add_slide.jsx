import React, { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Modal from '../../../components/common/modal.jsx';
import TextInput from '../../../components/common/text_input.jsx';
import { addSlide } from '../../../actions/training_modification_actions.js';
import { setValid, setInvalid, activateValidations, resetValidations } from '../../../actions/validation_actions.js';
import { firstValidationErrorMessage } from '../../../selectors';

const AddSlide = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const [slide, setSlide] = useState({
    title: '',
    slug: '',
    wiki_page: '',
  });
  const firstErrorMessage = useSelector(state => firstValidationErrorMessage(state));
  const dispatch = useDispatch();

  const handleInputChange = (key, value) => {
    setSlide(prevSlide => ({
      ...prevSlide,
      [key]: value
    }));
  };

  useEffect(() => {
    dispatch(resetValidations());
  }, []);

  const validateFields = () => {
    let valid = true;
    const message = I18n.t('training.validation_message');
    if (!slide.title.trim()) {
      dispatch(setInvalid('title', message));
      valid = false;
    } else {
      dispatch(setValid('title'));
    }

    if (!slide.slug.trim()) {
      dispatch(setInvalid('slug', message));
      valid = false;
    } else {
      dispatch(setValid('slug'));
    }

    if (!slide.wiki_page.trim()) {
      dispatch(setInvalid('wiki_page', message));
      valid = false;
    } else {
      dispatch(setValid('wiki_page'));
    }

    return valid;
  };

  const submitHandler = () => {
    dispatch(activateValidations());

    if (validateFields()) {
      setSubmitting(true);
      dispatch(addSlide(props.library_id, props.module_id, slide, setSubmitting));
    }
  };

  let formStyle;
  if (submitting) {
    formStyle = { pointerEvents: 'none', opacity: '0.5' };
  }

  return (
    <>
      <Modal >
        <div className="container training-modification">
          <div className="wizard__panel active training_modal single_column small-container" style={formStyle}>
            <h3>{I18n.t('training.add_slide')}</h3>
            <p>{I18n.t('training.add_slide_msg')}</p>
            <div>
              <TextInput
                id="title"
                onChange={handleInputChange}
                value={slide.title}
                value_key="title"
                required
                editable
                label={I18n.t('training.slide_title')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.slide_title')}`}
              />
              <TextInput
                id="slug"
                onChange={handleInputChange}
                value={slide.slug}
                value_key="slug"
                required
                editable
                label={I18n.t('training.slide_slug')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.slide_slug')}`}
              />
              <TextInput
                id="wiki_page"
                onChange={handleInputChange}
                value={slide.wiki_page}
                value_key="wiki_page"
                required
                editable
                label={I18n.t('training.slide_wiki_page')}
                placeholder={`${I18n.t('training.enter')} ${I18n.t('training.slide_wiki_page')}`}
              />
              <button className="button light" onClick={props.toggleModal}>{I18n.t('training.cancel')}</button>
              <span className="validation-error"> &nbsp; {firstErrorMessage || '\xa0'}</span>
              <button className="button dark right" onClick={submitHandler}>{I18n.t('training.add')}</button>
            </div>
          </div>
        </div>
      </Modal>
    </>
  );
};

export default AddSlide;
