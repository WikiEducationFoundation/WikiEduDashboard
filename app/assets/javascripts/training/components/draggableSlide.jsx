import React, { useState } from 'react';
import { useBlockDrag } from '../../hooks/useBlockDrag';

const DraggableSlide = ({
  slide,
  heading,
  description,
  canDrag,
  animating,
  onDrag,
  canSlideMoveUp,
  canSlideMoveDown,
  onSlideMoveUp,
  onSlideMoveDown,
  index
  }) => {
  const [isHoverArrowDown, setIsHoverArrowDown] = useState(false);
  const [isHoverArrowUp, setIsHoverArrowUp] = useState(false);
  const { ref, isDragging, handlerId } = useBlockDrag({
    block: slide,
    canDrag,
    isAnimating: animating,
    onBlockDragOver: onDrag
  });

  const opacity = isDragging ? 0.5 : 1;

  return (
    <div key={heading} className={'program-description'} style={{ opacity }} ref={ref} data-handler-id={handlerId}>
      <div className="draggable-slide-container">
        <div className="program-description__header">
          <h4><strong>{heading}</strong></h4>
          {description.split('\n').map((paragraph, i) => paragraph && <p key={i}>{paragraph}</p>)}
        </div>
        <div className="reorder-slide-buttons">
          <button className="button border reordering_icons" onClick={() => onSlideMoveDown(index)}onMouseEnter={() => setIsHoverArrowDown(true)} onMouseLeave={() => setIsHoverArrowDown(false)} disabled={!canSlideMoveDown}>
            <i className={`icon ${isHoverArrowDown ? 'icon-arrow-down_white' : 'icon-arrow-down'}`} />
          </button>
          <button className="button border reordering_icons" onClick={() => onSlideMoveUp(index)} onMouseEnter={() => setIsHoverArrowUp(true)} onMouseLeave={() => setIsHoverArrowUp(false)} disabled={!canSlideMoveUp}>
            <i className={`icon ${isHoverArrowUp ? 'icon-arrow-up_white' : 'icon-arrow-up'}`} />
          </button>
        </div>
      </div>
    </div>
  );
};

export default DraggableSlide;
