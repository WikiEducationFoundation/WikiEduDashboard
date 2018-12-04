import React from 'react';
import TransitionGroup from 'react-transition-group/TransitionGroup';
import CSSTransition from 'react-transition-group/CSSTransition';

const CSSTransitionGroup = props => (
  <TransitionGroup>
    <CSSTransition {...props} />
  </TransitionGroup>
);

export default CSSTransitionGroup;
