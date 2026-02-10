import { Flipped } from 'react-flip-toolkit';
import React, { useState, useEffect } from 'react';
import DraggableSlide from './draggableSlide';

export default function SpringSlide({
  slide,
  index,
  id,
  heading,
  description,
  onSlideDrag,
  onSlideMoveUp,
  onSlideMoveDown,
  totalSlides
}) {
  const [animating, setAnimating] = useState(false);
  const [canSlideMoveUp, setCanSlideMoveUp] = useState(false);
  const [canSlideMoveDown, setCanSlideMoveDown] = useState(false);

  useEffect(() => {
    setCanSlideMoveUp(index > 0);
    setCanSlideMoveDown(index < totalSlides - 1);
  }, [index, totalSlides]);

  return (
    <Flipped
      key={id}
      flipId={id}
      onComplete={() => {
        setAnimating(false);
      }}
      onStartImmediate={() => {
          setAnimating(true);
      }}
    >
      <ul className="week__block-list list-unstyled">
        <li>
          <DraggableSlide
            slide={slide}
            heading={heading}
            description={description}
            canDrag={true}
            animating={animating}
            onDrag={onSlideDrag}
            canSlideMoveUp={canSlideMoveUp}
            canSlideMoveDown={canSlideMoveDown}
            onSlideMoveUp={onSlideMoveUp}
            onSlideMoveDown={onSlideMoveDown}
            index={index}
          />
        </li>
      </ul>
    </Flipped>
  );
}
