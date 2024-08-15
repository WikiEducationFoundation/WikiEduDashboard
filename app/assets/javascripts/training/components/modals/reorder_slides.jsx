import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import { Flipper } from 'react-flip-toolkit';
import Modal from '../../../components/common/modal.jsx';
import SpringSlide from '../springSlide.jsx';
import { reorderSlides } from '../../../actions/training_modification_actions.js';

// Choose slides to remove from training module
const ReorderSlides = (props) => {
  const [submitting, setSubmitting] = useState(false);
  const dispatch = useDispatch();
  const [slides, setSlides] = useState(
    props.slidesAry.map(slide => ({
      order: slide.order,
      slug: slide.slug,
      title: slide.title,
      wiki_page: slide.wiki_page,
    }))
  );

  const submitHandler = () => {
    setSubmitting(true);
    dispatch(reorderSlides(props.module_id, slides, setSubmitting));
  };

  const onSlideDragOver = (draggedItem, hoveredItem) => {
    const dragIndex = draggedItem.order;
    const hoverIndex = hoveredItem.order;
    const updatedSlides = [...slides];
    const [removed] = updatedSlides.splice(dragIndex, 1);
    updatedSlides.splice(hoverIndex, 0, removed);

    setSlides(updatedSlides);
  };

  const onSlideMoveUp = (slideIndex) => {
    const updatedSlides = [...slides];
    const [removed] = updatedSlides.splice(slideIndex, 1);
    updatedSlides.splice(slideIndex - 1, 0, removed);
    setSlides(updatedSlides);
  };

  const onSlideMoveDown = (slideIndex) => {
    const updatedSlides = [...slides];
    const [removed] = updatedSlides.splice(slideIndex, 1);
    updatedSlides.splice(slideIndex + 1, 0, removed);
    setSlides(updatedSlides);
  };

  const springSlides = slides.map((slide, index) => {
    slide.order = index;
    return <SpringSlide
      key={slide.slug}
      slide={slide}
      index={index}
      id={slide.slug}
      heading={slide.title}
      description={slide.wiki_page}
      onSlideDrag={onSlideDragOver}
      onSlideMoveUp={onSlideMoveUp}
      onSlideMoveDown={onSlideMoveDown}
      totalSlides={slides.length}
    />;
  });

  const formClassName = submitting ? 'form-submitting' : '';

  return (
    <Modal>
      <div className="container training-modification">
        <div className={`wizard__panel active training_modal single_column wide-container reorder-slides ${formClassName}`}>
          <h3>{I18n.t('training.change_order')}</h3>
          <p>{I18n.t('training.change_order_msg')}</p>
          <DndProvider backend={HTML5Backend}>
            <Flipper flipKey={slides.map(slide => slide.slug).join('')} spring="stiff">
              <div className="remove-slide-container" style={{ paddingBottom: '20px' }}>
                {springSlides}
              </div>
            </Flipper>
          </DndProvider>
          <button className="button light" onClick={props.toggleModal}>{I18n.t('training.back')}</button>
          <button className="button dark right" onClick={submitHandler}>
            {I18n.t('training.save')}
          </button>
        </div>
      </div>
    </Modal>
  );
};

export default ReorderSlides;
