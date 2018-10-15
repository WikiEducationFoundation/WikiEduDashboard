
import deepFreeze from 'deep-freeze';
import '../testHelper';
import training from '../../app/assets/javascripts/reducers/training.js';
import {
  RECEIVE_TRAINING_MODULE,
  SET_CURRENT_SLIDE,
  MENU_TOGGLE,
  SLIDE_COMPLETED
} from '../../app/assets/javascripts/constants';

describe('training reducer', () => {
  const initialState = training(undefined, {});
  deepFreeze(initialState);


  const firstSlide = {
    title: 'Welcome!',
    slug: 'first-slide',
    id: 101,
    content: 'First slide',
    index: 1,
    completed: false,
    enabled: true
  };
  const secondSlide = {
    title: 'Bye!',
    slug: 'slide-two',
    id: 102,
    content: 'Second slide',
    index: 2,
    completed: false,
    enabled: true
  };
  const trainingModuleData = {
    slide: 'first-slide',
    valid: true,
    training_module: {
      slug: 'module-slug',
      id: 200,
      wiki_page: null,
      slides: [
        firstSlide,
        secondSlide
      ]
    }
  };
  deepFreeze(trainingModuleData);
  const initialStateWithModule = training(initialState, { type: RECEIVE_TRAINING_MODULE, data: trainingModuleData });
  deepFreeze(initialStateWithModule);


  it('receives modules', () => {
    const output = training(initialState, { type: RECEIVE_TRAINING_MODULE, data: trainingModuleData });
    expect(output.currentSlide.slug).to.eq('first-slide');
  });

  it('sets the current slide', () => {
    const output = training(initialStateWithModule, { type: SET_CURRENT_SLIDE, data: { slide: 'slide-two' } });
    expect(output.currentSlide.slug).to.eq('slide-two');
  });

  it('sets a slide and module as completed', () => {
    const output = training(initialStateWithModule, { type: SLIDE_COMPLETED, data: { slide: { id: 102 }, completed: true } });
    expect(output.enabledSlides).to.include(102);
    expect(output.completed).to.eq(true);
  });

  it('opens and closes the menu', () => {
    expect(initialStateWithModule.menuIsOpen).to.eq(false);
    const output = training(initialStateWithModule, { type: MENU_TOGGLE, data: { currently: false } });
    expect(output.menuIsOpen).to.eq(true);

    deepFreeze(output);
    const outputTwo = training(output, { type: MENU_TOGGLE, data: { currently: true } });
    expect(outputTwo.menuIsOpen).to.eq(false);
  });
});
