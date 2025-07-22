import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { extend } from 'lodash-es';

const SlideMenu = (props) => {
  useEffect(() => {
    window.addEventListener('click', props.closeMenu, false);

    return () => {
      window.removeEventListener('click', props.closeMenu, false);
    };
  }, []);

  const linkParams = () => {
    return {
      library_id: props.params.library_id,
      module_id: props.params.module_id
    };
  };

  const _slideLink = (params) => {
    return `/training/${params.library_id}/${params.module_id}/${params.slide_id}`;
  };

    if (!props.slides) { return <div />; }
    // need the slide index because overflow: hidden cuts off li numbering
    const slides = props.slides.map((slide, loopIndex) => {
      const current = slide.id === props.currentSlide.id;
      const liClass = current ? 'current' : '';
      const newParams = extend(linkParams(), { slide_id: slide.slug });
      const slideLink = _slideLink(newParams);
      // a slide is enabled if it comes back from the API as such,
      // it is set enabled in the parent component,
      // or it's the current slide
      let slideTitle = slide.title;
      if (slide.translations && slide.translations[I18n.locale]) {
        slideTitle = slide.translations[I18n.locale].title;
      }
      const enabled = (slide.enabled === true || props.enabledSlides.indexOf(slide.id) >= 0) && !current;
      return (
        <li key={[slide.id, loopIndex].join('-')} onClick={props.onClick} className={liClass}>
          <a disabled={!enabled} href={slideLink}>
            {loopIndex + 1}. {slideTitle}
          </a>
        </li>
      );
    }
    );

    let menuClass = 'slide__menu__nav__dropdown ';
    menuClass += props.menuClass;

    return (
      <div className={menuClass}>
        <span className="dropdown__close pull-right" onClick={props.onClick}>&times;</span>
        <h1 className="h5 capitalize">{I18n.t('training.table_of_contents')}</h1>
        <ol>
          {slides}
        </ol>
      </div>
    );
  };
SlideMenu.displayName = 'SlideMenu';

SlideMenu.propTypes = {
    closeMenu: PropTypes.func.isRequired,
    onClick: PropTypes.func.isRequired,
    slides: PropTypes.array,
    currentSlide: PropTypes.object,
    enabledSlides: PropTypes.array,
    menuClass: PropTypes.string
  };
export default SlideMenu;
