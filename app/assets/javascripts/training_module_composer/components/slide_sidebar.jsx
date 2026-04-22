import React, { useRef } from 'react';
import { DndProvider, useDrag, useDrop } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';

const DRAG_TYPE = 'training-composer-slide';

const CollisionMark = ({ collision }) => {
  if (!collision) return null;
  const title = collision === 'existing'
    ? 'Slug conflicts with an existing training slide'
    : 'Slug duplicates another slide in this draft';
  return (
    <span
      className="training_module_composer__sidebar__collision"
      title={title}
      aria-label={title}
    >
      ⚠
    </span>
  );
};

const NavItem = ({ slide, index, selectedIndex, onSelect, collision }) => (
  <li
    className={`training_module_composer__sidebar__item${index === selectedIndex ? ' selected' : ''}`}
  >
    <button
      type="button"
      className="training_module_composer__sidebar__thumb"
      onClick={() => onSelect(index)}
    >
      <span className="training_module_composer__sidebar__position">{index + 1}</span>
      <span className="training_module_composer__sidebar__title">
        {slide.title || <em>Untitled slide</em>}
      </span>
      <CollisionMark collision={collision} />
    </button>
  </li>
);

const EditItem = ({
  slide, index, selectedIndex, onSelect, onDelete, onMove, slideCount, collision
}) => {
  const ref = useRef(null);

  const [{ isDragging }, drag] = useDrag({
    type: DRAG_TYPE,
    item: { index },
    collect: monitor => ({ isDragging: monitor.isDragging() })
  });

  const [, drop] = useDrop({
    accept: DRAG_TYPE,
    hover: (item, monitor) => {
      if (!ref.current) return;
      const dragIndex = item.index;
      const hoverIndex = index;
      if (dragIndex === hoverIndex) return;

      const hoverRect = ref.current.getBoundingClientRect();
      const hoverMiddleY = (hoverRect.bottom - hoverRect.top) / 2;
      const clientOffset = monitor.getClientOffset();
      const hoverClientY = clientOffset.y - hoverRect.top;

      if (dragIndex < hoverIndex && hoverClientY < hoverMiddleY) return;
      if (dragIndex > hoverIndex && hoverClientY > hoverMiddleY) return;

      onMove(dragIndex, hoverIndex);
      item.index = hoverIndex;
    }
  });

  drag(drop(ref));

  const classes = [
    'training_module_composer__sidebar__item',
    'editing',
    index === selectedIndex ? 'selected' : '',
    isDragging ? 'dragging' : ''
  ].filter(Boolean).join(' ');

  return (
    <li ref={ref} className={classes}>
      <span className="training_module_composer__sidebar__handle" aria-hidden="true">⋮⋮</span>
      <button
        type="button"
        className="training_module_composer__sidebar__thumb"
        onClick={() => onSelect(index)}
      >
        <span className="training_module_composer__sidebar__position">{index + 1}</span>
        <span className="training_module_composer__sidebar__title">
          {slide.title || <em>Untitled slide</em>}
        </span>
        <CollisionMark collision={collision} />
      </button>
      <div className="training_module_composer__sidebar__actions">
        <button
          type="button"
          className="button tiny"
          onClick={() => onMove(index, index - 1)}
          disabled={index === 0}
          aria-label="Move up"
        >
          ↑
        </button>
        <button
          type="button"
          className="button tiny"
          onClick={() => onMove(index, index + 1)}
          disabled={index === slideCount - 1}
          aria-label="Move down"
        >
          ↓
        </button>
        <button
          type="button"
          className="button tiny danger"
          onClick={() => onDelete(index)}
          aria-label="Delete slide"
        >
          ×
        </button>
      </div>
    </li>
  );
};

const SlideSidebar = ({
  slides, selectedIndex, onSelect, onAdd, onDelete, onMove,
  editMode, onToggleEditMode, collisionForSlide
}) => {
  const list = (
    <ol className="training_module_composer__sidebar__list">
      {slides.map((slide, index) => (editMode ? (
        <EditItem
          key={index}
          slide={slide}
          index={index}
          selectedIndex={selectedIndex}
          onSelect={onSelect}
          onDelete={onDelete}
          onMove={onMove}
          slideCount={slides.length}
          collision={collisionForSlide ? collisionForSlide(index) : null}
        />
      ) : (
        <NavItem
          key={index}
          slide={slide}
          index={index}
          selectedIndex={selectedIndex}
          onSelect={onSelect}
          collision={collisionForSlide ? collisionForSlide(index) : null}
        />
      )))}
    </ol>
  );

  return (
    <aside className={`training_module_composer__sidebar${editMode ? ' edit-mode' : ''}`}>
      <div className="training_module_composer__sidebar__header">
        <h3>Slides ({slides.length})</h3>
        <div className="training_module_composer__sidebar__header__actions">
          <button
            type="button"
            className={`button tiny${editMode ? ' dark' : ''}`}
            onClick={onToggleEditMode}
            aria-pressed={editMode}
          >
            {editMode ? 'Done' : 'Edit'}
          </button>
          <button type="button" className="button small" onClick={onAdd}>+ Add</button>
        </div>
      </div>

      {editMode ? <DndProvider backend={HTML5Backend}>{list}</DndProvider> : list}
    </aside>
  );
};

export default SlideSidebar;
