import React from 'react';
import TransitionGroup from 'react-transition-group/TransitionGroup';
import CSSTransition from 'react-transition-group/CSSTransition';

const CSSTransitionGroup = (props) => {
  const children = React.Children.map(props.children, child =>
    <CSSTransition {...props}>{child}</CSSTransition>
  );
  return (
    <TransitionGroup>
      {children}
    </TransitionGroup>
  );
};

export default CSSTransitionGroup;
