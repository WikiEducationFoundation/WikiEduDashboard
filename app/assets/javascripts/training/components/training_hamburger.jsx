import React from 'react';
import SlideMenu from './slide_menu.jsx';
import { useDispatch, useSelector } from 'react-redux';
import {toggleMenuOpen } from '../../actions/training_actions.js';
import { useParams } from "react-router-dom";

const TrainingHamburger = () => {
    const dispatch = useDispatch();
    const routeParams = useParams()
    const training = useSelector(state => state.training);
    const menuClass = training.menuIsOpen === false ? 'hidden' : 'shown';
     const closeMenu_FC = (e) => {
        if (training.menuIsOpen) {
        e.stopPropagation();
        dispatch(toggleMenuOpen({ currently: true }));
        }
    };

    const toggleMenuOpen_FC = (e) => {
        e.stopPropagation();
        dispatch(toggleMenuOpen({ currently: training.menuIsOpen }));
    };

    return (
        <div>
        <div
          role="button"
          tabIndex={0}
          className="pull-right training__slide__nav"
          onClick={toggleMenuOpen_FC}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              toggleMenuOpen_FC();
            }
          }}
        >
          <div className="pull-right hamburger">
            <span className="hamburger__bar" />
            <span className="hamburger__bar" />
            <span className="hamburger__bar" />
          </div>
          <span className="pull-right training__slide__page-label">
            {I18n.t('training.page_number', { number: training.currentSlide.index, total: training.slides.length })}
          </span>
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
        </div>
    );
}

export default TrainingHamburger;