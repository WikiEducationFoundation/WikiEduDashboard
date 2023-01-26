import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router';
import { extend } from 'lodash-es';
import { useDispatch, useSelector } from 'react-redux';
import { fetchTrainingModule, setSlideCompleted, setCurrentSlide, toggleMenuOpen } from '../../actions/training_actions.js';
import SlideLink from './slide_link.jsx';
import SlideMenu from './slide_menu.jsx';
import Quiz from './quiz.jsx';
import Notifications from '../../components/common/notifications.jsx';
import I18n from 'i18n-js';
import Alert from './Alert';




const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

const __guard__ = (value, transform) => {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
};

const moduleId = (params) => {
  return __guard__(params, x => x.module_id);
};


const returnToLink = () => {
  return document.getElementById('react_root').getAttribute('data-return-to');
};

const userLoggedIn = () => {
  return typeof __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id')) === 'string';
};

const trainingUrl = (params) => {
  return `/training/${params.library_id}/${params.module_id}/${params.slide_id}`;
};

const disableNext = (training) => {
  return Boolean(training.currentSlide.assessment) && !training.currentSlide.answeredCorrectly;
};

const getSlideInfo = (training, locale) => {
  let slideTitle;
  let assessment;
  let rawHtml;
  if (training.currentSlide.translations && training.currentSlide.translations[locale]) {
    slideTitle = training.currentSlide.translations[locale].title;
    rawHtml = md.render(training.currentSlide.translations[locale].content);
    if (training.currentSlide.translations[locale].assessment) {
      assessment = training.currentSlide.translations[locale].assessment;
    }
  } else {
    slideTitle = training.currentSlide.title;
    if (training.currentSlide.content) {
      rawHtml = md.render(training.currentSlide.content);
    }
    if (training.currentSlide.assessment) {
      assessment = training.currentSlide.assessment;
    }
  }
  return { slideTitle, assessment, rawHtml };
};

const keys = { rightKey: 39, leftKey: 37 };


//helper variables for Alerthandler function.
let count = 0; 
let nooftimes = 0;  
const enteringTime = new Date().getTime();


const TrainingSlideHandler = () => {
  const training = useSelector(state => state.training);
  const routeParams = useParams();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const [baseTitle, setBaseTitle] = useState('');


  const setSlideCompleted_FC = (slideId) => {
    const userId = __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id'));
    if (!userId) { return; }
    dispatch(setSlideCompleted({
      slide_id: slideId,
      module_id: moduleId(routeParams),
      user_id: userId
    }));
  };


  const [isShown, setIsShown] = useState(false);

  // this function checks whether alert should be shown or not.
  const Alerthandler = (event) => { 
    if(routeParams.library_id === 'students'){
    count = count + 1;
    const clickingTime = new Date().getTime() - enteringTime;
    if (count > 3  && clickingTime < 10000 && nooftimes < 2){
      setIsShown(current => !current);
      nooftimes = nooftimes + 1;
      count = 0;
    } }
  };

  const next = () => {
    const nextSlug = training.nextSlide.slug;
    dispatch(setCurrentSlide(nextSlug));
    setSlideCompleted_FC(nextSlug);
    Alerthandler();
  };

  const prev = () => {
    dispatch(setCurrentSlide(training.previousSlide.slug));
  };

  // runs when the component is first rendered
  // fetches the initial data and sets the base title
  useEffect(() => {
    setBaseTitle(document.title);
    const slideId = __guard__(routeParams, x => x.slide_id);
    const userId = __guard__(document.getElementById('main'), x => x.getAttribute('data-user-id'));
    dispatch(fetchTrainingModule({ module_id: moduleId(routeParams), slide_id: slideId, user_id: userId }));
  }, []);

  // runs whenever the training from the redux store changes
  // which means its run essentially when the user goes from one slide to another
  // changes the page title according to the slide title and updates the event listener
  useEffect(() => {
    const handleKeyPress = (e) => {
      const navParams = { library_id: routeParams.library_id, module_id: routeParams.module_id };
      if (e.which === keys.leftKey && training.previousSlide) {
        const params = extend(navParams, { slide_id: training.previousSlide.slug });
        prev();
        return navigate(trainingUrl(params));
      }
      if (e.which === keys.rightKey && training.nextSlide) {
        if (disableNext(training)) { return; }
        const params = extend(navParams, { slide_id: training.nextSlide.slug });
        next();
        return navigate(trainingUrl(params));
        
      }
    };

    window.addEventListener('keyup', handleKeyPress);

    // training has changed, so update the title of the slide
    const { slideTitle } = getSlideInfo(training, I18n.locale);
    document.title = `${slideTitle} - ${baseTitle}`;
 
    return () => {
      // cleanup. Removes the old event listener
      return window.removeEventListener('keyup', handleKeyPress);
    };
  }, [training]);

  if (training.loading === true) {
    return (
      <div className="training-loader">
        <h1 className="h2">Loading…</h1>
        <div className="training-loader__spinner" />
      </div>
    );
  }
  if (training.valid === false) { 
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

  if (__guard__(training.nextSlide, x1 => x1.slug)) {
    nextLink = (
      <>
      <SlideLink
        slideId={training.nextSlide.slug}
        buttonText={training.currentSlide.buttonText || I18n.t('training.next')}
        disabled={disableNext(training)}
        button={true}
        params={routeParams}
        onClick={next}
      />
         {isShown && <Alert/>}
      </>
    );
  } else {
    let nextHref = returnToLink();
    if (!nextHref) {
      nextHref = userLoggedIn() ? '/' : `/training/${routeParams.library_id}`;
    }
    if (training.completed) {
      nextLink = <a href={nextHref} className="slide-nav btn btn-primary pull-right"> {training.currentSlide.buttonText || I18n.t('training.done')} </a>;
    } else {
      nextLink = <a href={nextHref} className="slide-nav btn btn-primary disabled pull-right"> {training.currentSlide.buttonText || I18n.t('training.done')} </a>;
    }

    if (training.completed === false) {
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
  if (!userLoggedIn()) {
    loginWarning = (
      <div className="training__slide__notification" key="not_logged_in">
        <div className="container">
          <p>{I18n.t('training.logged_out')}</p>
        </div>
      </div>
    );
  }

  let previousLink;
  if (__guard__(training.previousSlide, x2 => x2.slug)) {
    previousLink = (
      <SlideLink
        slideId={training.previousSlide.slug}
        buttonText={I18n.t('training.previous')}
        params={routeParams}
        onClick={prev}
      />

    );
  }

  const { slideTitle, assessment, rawHtml } = getSlideInfo(training, I18n.locale);

  const menuClass = training.menuIsOpen === false ? 'hidden' : 'shown';

  let quiz;
  if (training.currentSlide.assessment) {
    quiz = (
      <Quiz
        question={assessment.question}
        answers={assessment.answers}
        selectedAnswer={training.currentSlide.selectedAnswer}
        correctAnswer={training.currentSlide.assessment.correct_answer_id}
      />
    );
  }

  let titlePrefix;
  if (training.currentSlide.title_prefix) {
    titlePrefix = (
      <h2 className="training__slide__title-prefix">{training.currentSlide.title_prefix}</h2>
    );
  }

 let sourceLink;
 if (training.currentSlide.wiki_page) {
   sourceLink = <span><a href={`https://meta.wikimedia.org/wiki/${training.currentSlide.wiki_page}`} target="_blank">wiki source</a></span>;
 }


  const toggleMenuOpen_FC = (e) => {
    e.stopPropagation();
    dispatch(toggleMenuOpen({ currently: training.menuIsOpen }));
  };

  const closeMenu_FC = (e) => {
    if (training.menuIsOpen) {
      e.stopPropagation();
      dispatch(toggleMenuOpen({ currently: true }));
    }
  };

  return (
    <div>
      <Notifications />
      <header>
        <div className="pull-right training__slide__nav" onClick={toggleMenuOpen_FC}>
          <div className="pull-right hamburger">
            <span className="hamburger__bar" />
            <span className="hamburger__bar" />
            <span className="hamburger__bar" />
          </div>
          <h3 className="pull-right">
            <a href="" onFocus={toggleMenuOpen_FC}>{I18n.t('training.page_number', { number: training.currentSlide.index, total: training.slides.length })}</a>
          </h3>
        </div>
        <SlideMenu
          closeMenu={closeMenu_FC}
          onClick={toggleMenuOpen_FC}
          menuClass={menuClass}
          currentSlide={training.currentSlide}
          params={routeParams}
          enabledSlides={training.enabledSlides}
          slides={training.slides}
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
};

export default TrainingSlideHandler;
