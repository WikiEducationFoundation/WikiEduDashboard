import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { compact } from 'lodash-es';
import { connect } from 'react-redux';
import { fetchTrainingModule } from '../../actions/training_actions.js';
import AddSlide from './modals/add_slide.jsx';
import RemoveSlides from './modals/remove_slide.jsx';
import ReorderSlides from './modals/reorder_slides.jsx';

const TrainingModuleHandler = (props) => {
  useEffect(() => {
    const moduleId = document.getElementById('react_root').getAttribute('data-module-id');
    props.fetchTrainingModule({ module_id: moduleId });
  }, []);

  const toggleAddSlideModal = () => {
    setShowAddSlideModal(!showAddSlideModal);
  };

  const toggleRemoveSlideModal = () => {
    setShowRemoveSlideModal(!showRemoveSlideModal);
  };

  const toggleReorderSlideModal = () => {
    setShowReorderSlideModal(!showReorderSlideModal);
  };

  const [showRemoveSlideModal, setShowRemoveSlideModal] = useState(false);
  const [showAddSlideModal, setShowAddSlideModal] = useState(false);
  const [showReorderSlideModal, setShowReorderSlideModal] = useState(false);
  const { library_id, module_id } = useParams();
  const locale = I18n.locale;
  const slidesAry = compact(props.training.module.slides);
  const slides = slidesAry.map((slide, i) => {
    const disabled = !slide.enabled;
    const slideLink = `${props.training.module.slug}/${slide.slug}`;
    let liClassName;
    if (disabled) { liClassName = 'disabled'; }
    let summary;
    if (slide.summary) {
      summary = <div className="ui-text small sidebar-text">{slide.summary}</div>;
    }
    let slideTitle = slide.title;
    if (slide.translations && slide.translations[locale]) {
      slideTitle = slide.translations[locale].title;
    }
    return (
      <li className={liClassName} key={i}>
        <a disabled={disabled} href={slideLink}>
          <h3 className="h5">{slideTitle}</h3>
          {summary}
        </a>
      </li>
    );
  }
  );
  let moduleSource;
  if (props.training.module.wiki_page) {
    moduleSource = (
      <div className="training-module-source">
        <a href={`https://meta.wikimedia.org/wiki/${props.training.module.wiki_page}`} target="_blank">{I18n.t('training.view_module_source')}</a>
        <br />
        <a href={`/reload_trainings?module=${props.training.module.slug}`}>{I18n.t('training.reload_from_source')}</a>
      </div>
    );
  }

  return (
    <div>
      {showAddSlideModal && <AddSlide library_id={library_id} module_id={module_id} toggleModal={toggleAddSlideModal} />}
      {showRemoveSlideModal && <RemoveSlides module_id={module_id} slidesAry={slidesAry} toggleModal={toggleRemoveSlideModal} />}
      {showReorderSlideModal && <ReorderSlides module_id={module_id} slidesAry={slidesAry} toggleModal={toggleReorderSlideModal} />}
      <div className="training__toc-container">
        <h1 className="h4 capitalize"> {I18n.t('training.table_of_contents')} <span className="pull-right total-slides">({slidesAry.length})</span></h1>
        <ol className="scrollable_slides_container">
          {slides}
        </ol>
        {moduleSource}
        <div className="training-modification training_slide_modification_buttons">
          <button className="button dark" onClick={toggleReorderSlideModal}>{I18n.t('training.change_order')}</button>
          <button className="button dark" onClick={toggleAddSlideModal}>{I18n.t('training.add_slide')}</button>
          <button className="button danger" onClick={toggleRemoveSlideModal}>{I18n.t('training.remove_slide')}</button>
        </div>
      </div>
    </div>
  );
};

TrainingModuleHandler.displayName = 'TrainingModuleHandler';
const mapStateToProps = state => ({
  training: state.training
});

const mapDispatchToProps = {
  fetchTrainingModule
};

export default connect(mapStateToProps, mapDispatchToProps)(TrainingModuleHandler);
