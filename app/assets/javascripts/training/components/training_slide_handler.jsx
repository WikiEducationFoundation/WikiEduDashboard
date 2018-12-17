import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { browserHistory } from 'react-router';
import _ from 'lodash';
import { connect } from 'react-redux';
import { fetchTrainingModule, setSlideCompleted, setCurrentSlide, toggleMenuOpen } from '../../actions/training_actions.js';
import SlideLink from './slide_link.jsx';
import SlideMenu from './slide_menu.jsx';
import Quiz from './quiz.jsx';
import Notifications from '../../components/common/notifications.jsx';

const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

const TrainingSlideHandler = createReactClass({
  displayName: 'TrainingSlideHandler',

  propTypes: {
    params: PropTypes.object
  },

  componentDidMount() {
    const slideId = __guard__(this.props.params, x => x.slide_id);
    const userId = __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id'));
    this.props.fetchTrainingModule({ module_id: this.moduleId(), slide_id: slideId, user_id: userId });
    window.addEventListener('keyup', this.handleKeyPress);
  },

  componentWillUnmount() {
    return window.removeEventListener('keyup', this.handleKeyPress);
  },

  setSlideCompleted(slideId) {
    const userId = __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id'));
    if (!userId) { return; }
    return this.props.setSlideCompleted({
      slide_id: slideId,
      module_id: this.moduleId(),
      user_id: userId
    });
  },

  next() {
    const nextSlug = this.props.training.nextSlide.slug;
    this.props.setCurrentSlide(nextSlug);
    this.setSlideCompleted(nextSlug);
  },

  prev() {
    this.props.setCurrentSlide(this.props.training.previousSlide.slug);
  },

  moduleId() {
    return __guard__(this.props.params, x => x.module_id);
  },

  toggleMenuOpen(e) {
    e.stopPropagation();
    return this.props.toggleMenuOpen({ currently: this.props.training.menuIsOpen });
  },

  closeMenu(e) {
    if (this.props.training.menuIsOpen) {
      e.stopPropagation();
      return this.props.toggleMenuOpen({ currently: true });
    }
  },

  userLoggedIn() {
    return typeof __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id')) === 'string';
  },

  keys: { rightKey: 39, leftKey: 37 },

  disableNext() {
    return Boolean(this.props.training.currentSlide.assessment) && !this.props.training.currentSlide.answeredCorrectly;
  },

  returnToLink() {
    return document.getElementById('react_root').getAttribute('data-return-to');
  },

  trainingUrl(params) {
    return `/training/${params.library_id}/${params.module_id}/${params.slide_id}`;
  },

  handleKeyPress(e) {
    const navParams = { library_id: this.props.params.library_id, module_id: this.props.params.module_id };
    if (e.which === this.keys.leftKey && this.props.training.previousSlide) {
      const params = _.extend(navParams, { slide_id: this.props.training.previousSlide.slug });
      this.prev();
      browserHistory.push(this.trainingUrl(params));
    }
    if (e.which === this.keys.rightKey && this.props.training.nextSlide) {
      if (this.disableNext()) { return; }
      const params = _.extend(navParams, { slide_id: this.props.training.nextSlide.slug });
      this.next();
      return browserHistory.push(this.trainingUrl(params));
    }
  },

  render() {
    if (this.props.training.loading === true) {
      return (
        <div className="training-loader">
          <h1 className="h2">Loading…</h1>
          <div className="training-loader__spinner" />
        </div>
      );
    }
    if (this.props.training.valid === false) {
      return (
        <div className="training__slide__notification" key="invalid">
          <div className="container">
            <p>{I18n.t('training.invalid')}</p>
          </div>
        </div>
      );
    }
    let nextLink;
    let pendingWarning;
    if (__guard__(this.props.training.nextSlide, x1 => x1.slug)) {
      nextLink = (
        <SlideLink
          slideId={this.props.training.nextSlide.slug}
          buttonText={this.props.training.currentSlide.buttonText || I18n.t('training.next')}
          disabled={this.disableNext()}
          button={true}
          params={this.props.params}
          onClick={this.next}
        />
      );
    } else {
      let nextHref = this.returnToLink();
      if (!nextHref) {
        nextHref = this.userLoggedIn() ? '/' : `/training/${this.props.params.library_id}`;
      }
      if (this.props.training.completed) {
        nextLink = <a href={nextHref} className="slide-nav btn btn-primary pull-right"> {I18n.t('training.done')} </a>;
      } else {
        nextLink = <a href={nextHref} className="slide-nav btn btn-primary disabled pull-right"> {I18n.t('training.done')} </a>;
      }

      if (this.props.training.completed === false) {
        pendingWarning = (
          <div className="training__slide__notification" key="pending">
            <div className="container">
              <p>{I18n.t('training.wait')}</p>
            </div>
          </div>
        );
      }
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
    if (__guard__(this.props.training.previousSlide, x2 => x2.slug)) {
      previousLink = (
        <SlideLink
          slideId={this.props.training.previousSlide.slug}
          buttonText={I18n.t('training.previous')}
          params={this.props.params}
          onClick={this.prev}
        />
      );
    }

    let slideTitle;
    let assessment;
    let rawHtml;
    const locale = I18n.locale;
    if (this.props.training.currentSlide.translations && this.props.training.currentSlide.translations[locale]) {
      slideTitle = this.props.training.currentSlide.translations[locale].title;
      rawHtml = md.render(this.props.training.currentSlide.translations[locale].content);
      if (this.props.training.currentSlide.translations[locale].assessment) {
        assessment = this.props.training.currentSlide.translations[locale].assessment;
      }
    } else {
      slideTitle = this.props.training.currentSlide.title;
      if (this.props.training.currentSlide.content) {
        rawHtml = md.render(this.props.training.currentSlide.content);
      }
      if (this.props.training.currentSlide.assessment) {
        assessment = this.props.training.currentSlide.assessment;
      }
    }

    const menuClass = this.props.training.menuIsOpen === false ? 'hidden' : 'shown';

    let quiz;
    if (this.props.training.currentSlide.assessment) {
      quiz = (
        <Quiz
          question={assessment.question}
          answers={assessment.answers}
          selectedAnswer={this.props.training.currentSlide.selectedAnswer}
          correctAnswer={this.props.training.currentSlide.assessment.correct_answer_id}
        />
      );
    }

    let titlePrefix;
    if (this.props.training.currentSlide.title_prefix) {
      titlePrefix = (
        <h2 className="training__slide__title-prefix">{this.props.training.currentSlide.title_prefix}</h2>
      );
    }

   let sourceLink;
   if (this.props.training.currentSlide.wiki_page) {
     sourceLink = <span><a href={`https://meta.wikimedia.org/wiki/${this.props.training.currentSlide.wiki_page}`} target="_blank">wiki source</a></span>;
   }

    return (
      <div>
        <Notifications />
        <header>
          <div className="pull-right training__slide__nav" onClick={this.toggleMenuOpen}>
            <div className="pull-right hamburger">
              <span className="hamburger__bar" />
              <span className="hamburger__bar" />
              <span className="hamburger__bar" />
            </div>
            <h3 className="pull-right">
              <a href="" onFocus={this.toggleMenuOpen}>{I18n.t('training.page_number', { number: this.props.training.currentSlide.index, total: this.props.training.slides.length })}</a>
            </h3>
          </div>
          <SlideMenu
            closeMenu={this.closeMenu}
            onClick={this.toggleMenuOpen}
            menuClass={menuClass}
            currentSlide={this.props.training.currentSlide}
            params={this.props.params}
            enabledSlides={this.props.training.enabledSlides}
            slides={this.props.training.slides}
          />
        </header>
        {loginWarning}
        {pendingWarning}
        <article className="training__slide">
          {titlePrefix}
          <h1>{slideTitle}</h1>
          <div className="markdown training__slide__content" dangerouslySetInnerHTML={{ __html: rawHtml }} />
          {quiz}
          <footer className="training__slide__footer">
            <span className="pull-left">{previousLink}</span>
            {sourceLink}
            <span className="pull-right">{nextLink}</span>
          </footer>
        </article>
      </div>
    );
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}

const mapStateToProps = state => ({
  training: state.training
});

const mapDispatchToProps = {
  fetchTrainingModule,
  setSlideCompleted,
  setCurrentSlide,
  toggleMenuOpen
};

export default connect(mapStateToProps, mapDispatchToProps)(TrainingSlideHandler);
