import React from 'react';
import createReactClass from 'create-react-class';
import _ from 'lodash';

import TrainingStore from '../stores/training_store.js';
import ServerActions from '../../actions/server_actions.js';

const getState = () => ({ training_module: TrainingStore.getTrainingModule() });

const TrainingModuleHandler = createReactClass({
  displayName: 'TrainingModuleHandler',
  mixins: [TrainingStore.mixin],
  getInitialState() {
    return getState();
  },

  componentWillMount() {
    const moduleId = document.getElementById('react_root').getAttribute('data-module-id');
    return ServerActions.fetchTrainingModule({ module_id: moduleId });
  },

  storeDidChange() {
    return this.setState(getState());
  },

  render() {
    const locale = I18n.locale;
    const slidesAry = _.compact(this.state.training_module.slides);
    const slides = slidesAry.map((slide, i) => {
      const disabled = !slide.enabled;
      const slideLink = `${this.state.training_module.slug}/${slide.slug}`;
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

    return (
      <div className="training__toc-container">
        <h1 className="h4 capitalize"> {I18n.t('training.table_of_contents')} <span className="pull-right total-slides">({slidesAry.length})</span></h1>
        <ol>
          {slides}
        </ol>
      </div>
    );
  }
});

export default TrainingModuleHandler;
