import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { useParams } from 'react-router-dom';
import SelectableBox from '../../../components/common/selectable_box.jsx';
import { removeSlides } from '../../../actions/training_modification_actions.js';
import Modal from '../../../components/common/modal.jsx';

// Choose slides to remove from training module
const RemoveSlides = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const { module_id } = useParams();
  const [slideSlugList, setSlideSlugList] = useState([]);
  const dispatch = useDispatch();

  const handleSlideSelection = (selectedSlide) => {
    setSlideSlugList((prev) => {
      if (prev.includes(selectedSlide)) {
          return prev.filter(slide => slide !== selectedSlide);
      }
      return [...prev, selectedSlide];
      }
    );
  };

  const submitHandler = () => {
    setSubmitting(true);
    dispatch(removeSlides(module_id, slideSlugList, setSubmitting));
  };

  const formClassName = submitting ? 'form-submitting' : '';

  return (
    <Modal>
      <div className="container training-modification">
        <div className={`wizard__panel active training_modal single_column remove-slide ${formClassName}`}>
          <h3>{I18n.t('training.remove_slide')}</h3>
          <p>{I18n.t('training.remove_slide_msg')}</p>
          <div className="remove-slide-container" style={{ paddingBottom: '20px' }}>
            {props.slidesAry.map(slide => (
              <SelectableBox
                key={slide.slug}
                onClick={() => handleSlideSelection(slide.slug)}
                heading={slide.title}
                description={slide.wiki_page}
                selected={slideSlugList.includes(slide.slug)}
              />
            ))}
          </div>
          <button className="button light" onClick={props.toggleModal}>{I18n.t('training.back')}</button>
          <button className="button dark right" onClick={submitHandler} disabled={!slideSlugList.length}>
            {I18n.t('training.remove')}
          </button>
        </div>
      </div>
    </Modal>
  );
};

export default RemoveSlides;
