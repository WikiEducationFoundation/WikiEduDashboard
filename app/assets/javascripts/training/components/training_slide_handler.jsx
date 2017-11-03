import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { browserHistory } from 'react-router';
import _ from 'lodash';

import TrainingStore from '../stores/training_store.js';
import TrainingActions from '../actions/training_actions.js';
import ServerActions from '../../actions/server_actions.js';
import SlideLink from './slide_link.jsx';
import SlideMenu from './slide_menu.jsx';
import Quiz from './quiz.jsx';

const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

const getState = () => TrainingStore.getState();

const TrainingSlideHandler = createReactClass({
  displayName: 'TrainingSlideHandler',

  propTypes: {
    params: PropTypes.object
  },

  mixins: [TrainingStore.mixin],

  getInitialState() {
    return {
      slide: {},
      menuIsOpen: false,
      currentSlide: {},
      nextSlide: {},
      previousSlide: {},
      slides: [],
      loading: true,
      enabledSlides: []
    };
  },

  componentWillMount() {
    const slideId = __guard__(this.props.params, x => x.slide_id);
    ServerActions.fetchTrainingModule({ module_id: this.moduleId(), current_slide_id: slideId });
    return this.setSlideCompleted(slideId);
  },

  componentDidMount() {
    window.addEventListener('keyup', this.handleKeyPress);
  },

  componentWillReceiveProps(newProps) {
    const { slide_id } = newProps.params;
    TrainingActions.setCurrentSlide(slide_id);
    this.setSlideCompleted(slide_id);
    return this.setState(getState(newProps));
  },

  componentWillUnmount() {
    return window.removeEventListener('keyup', this.handleKeyPress);
  },

  setSlideCompleted(slideId) {
    const userId = __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id'));
    if (!userId) { return; }
    return ServerActions.setSlideCompleted({
      slide_id: slideId,
      module_id: this.moduleId(),
      user_id: userId
    });
  },

  storeDidChange() {
    return this.setState(getState());
  },

  moduleId() {
    return __guard__(this.props.params, x => x.module_id);
  },
  toggleMenuOpen(e) {
    e.stopPropagation();
    return TrainingActions.toggleMenuOpen({ currently: this.state.menuIsOpen });
  },

  closeMenu(e) {
    if (this.state.menuIsOpen) {
      e.stopPropagation();
      return TrainingActions.toggleMenuOpen({ currently: true });
    }
  },
  userLoggedIn() {
    return typeof __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id')) === 'string';
  },

  keys: { rightKey: 39, leftKey: 37 },

  disableNext() {
    return Boolean(this.state.currentSlide.assessment) && !this.state.currentSlide.answeredCorrectly;
  },

  trainingUrl(params) {
    return `/training/${params.library_id}/${params.module_id}/${params.slide_id}`;
  },

  handleKeyPress(e) {
    const navParams = { library_id: this.props.params.library_id, module_id: this.props.params.module_id };
    if (e.which === this.keys.leftKey && this.state.previousSlide) {
      const params = _.extend(navParams, { slide_id: this.state.previousSlide.slug });
      browserHistory.push(this.trainingUrl(params));
    }
    if (e.which === this.keys.rightKey && this.state.nextSlide) {
      if (this.disableNext()) { return; }
      const params = _.extend(navParams, { slide_id: this.state.nextSlide.slug });
      return browserHistory.push(this.trainingUrl(params));
    }
  },

  render() {
    if (this.state.loading === true) {
      return (
        <div className="training-loader">
          <h1 className="h2">Loading…</h1>
          <div className="training-loader__spinner" />
        </div>
      );
    }

    if (this.state.loading === false && !__guard__(this.state.currentSlide, x => x.id)) {
      window.location = '/errors/file_not_found';
      return <div />;
    }

    let nextLink;
    if (__guard__(this.state.nextSlide, x1 => x1.slug)) {
      nextLink = (
        <SlideLink
          slideId={this.state.nextSlide.slug}
          buttonText={this.state.currentSlide.buttonText || "Next Page"}
          disabled={this.disableNext()}
          button={true}
          params={this.props.params}
        />
      );
    } else {
      const nextHref = this.userLoggedIn() ? '/' : `/training/${this.props.params.library_id}`;
      nextLink = <a href={nextHref} className="btn btn-primary pull-right">Done!</a>;
    }

    let loginWarning;
    if (!this.userLoggedIn()) {
      loginWarning = (
        <div className="training__slide__notification" key="not_logged_in">
          <div className="container">
            <p>{I18n.t('training.logged_out')}</p>
          </div>
        </div>
      );
    }

    let previousLink;
    if (__guard__(this.state.previousSlide, x2 => x2.slug)) {
      previousLink = (
        <SlideLink
          slideId={this.state.previousSlide.slug}
          direction="< Previous"
          params={this.props.params}
        />
      );
    }

    let slideTitle;
    let rawHtml;
    const locale = I18n.locale;
    if (this.state.currentSlide.translations && this.state.currentSlide.translations[locale]) {
      slideTitle = this.state.currentSlide.translations[locale].title;
      rawHtml = md.render(this.state.currentSlide.translations[locale].content);
    } else {
      slideTitle = this.state.currentSlide.title;
      if (this.state.currentSlide.content) {
        rawHtml = md.render(this.state.currentSlide.content);
      }
    }


    const menuClass = this.state.menuIsOpen === false ? 'hidden' : 'shown';

    let quiz;
    if (this.state.currentSlide.assessment) {
      const { assessment } = this.state.currentSlide;
      quiz = (
        <Quiz
          question={assessment.question}
          answers={assessment.answers}
          selectedAnswer={this.state.currentSlide.selectedAnswer}
          correctAnswer={this.state.currentSlide.assessment.correct_answer_id}
        />
      );
    }

    let titlePrefix;
    if (this.state.currentSlide.title_prefix) {
      titlePrefix = (
        <h2 className="training__slide__title-prefix">{this.state.currentSlide.title_prefix}</h2>
      );
    }

    return (
      <div>
        <header>
          <div className="pull-right training__slide__nav" onClick={this.toggleMenuOpen}>
            <div className="pull-right hamburger">
              <span className="hamburger__bar" />
              <span className="hamburger__bar" />
              <span className="hamburger__bar" />
            </div>
            <h3 className="pull-right">
              <a href="" onFocus={this.toggleMenuOpen}>Page {this.state.currentSlide.index} of {this.state.slides.length}</a>
            </h3>
          </div>
          <SlideMenu
            closeMenu={this.closeMenu}
            onClick={this.toggleMenuOpen}
            menuClass={menuClass}
            currentSlide={this.state.currentSlide}
            params={this.props.params}
            enabledSlides={this.state.enabledSlides}
            slides={this.state.slides}
          />
        </header>
        {loginWarning}
        <article className="training__slide">
          {titlePrefix}
          <h1>{slideTitle}</h1>
          <div className="markdown training__slide__content" dangerouslySetInnerHTML={{ __html: rawHtml }} />
          {quiz}
          <footer className="training__slide__footer">
            <span className="pull-left">{previousLink}</span>
            <span className="pull-right">{nextLink}</span>
          </footer>
        </article>
      </div>
    );
  }
});

export default TrainingSlideHandler;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
