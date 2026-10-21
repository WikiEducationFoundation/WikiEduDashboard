import React, { useEffect, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';

import Modal from '../../common/modal.jsx';
import Loading from '../../common/loading.jsx';
import WizardBlockRow from './WizardBlockRow.jsx';
import { fetchWizardBlockCatalog } from '../../../actions/wizard_block_actions';
import { addWizardBlock } from '../../../actions/timeline_actions';

// Admin-only: insert one of the standard blocks the assignment wizard builds
// into a week of an existing timeline — to restore a block that was deleted,
// replace one whose canonical copy has since been revised, or pick up a
// conditional variant the course did not originally qualify for.
//
// Every block is listed rather than only the matching ones, because an admin
// doing a repair usually wants precisely the block the course does not
// currently qualify for.
//
// Focus is managed by hand because the shared Modal does not do it: it moves
// into the filter when the picker opens (so that a screen reader announces the
// dialog), back to the button that opened it on cancel, and to the inserted
// block's title on add. Without that, focus falls to <body> at each step and a
// screen reader user hears nothing.

// The title input of a block that is open for editing.
const blockTitleInput = blockId => document.querySelector(`#block-${blockId} .block-title input`);

const AddWizardBlock = ({ course, weekId, describedBy }) => {
  const dispatch = useDispatch();
  const { catalog, loading } = useSelector(state => state.wizardBlocks);
  const [open, setOpen] = useState(false);
  const [filter, setFilter] = useState('');
  const [focusBlockId, setFocusBlockId] = useState(null);
  const triggerRef = useRef(null);
  const filterRef = useRef(null);

  useEffect(() => {
    if (open) filterRef.current?.focus();
  }, [open]);

  // Focus the inserted block's title once it exists. The block reaches the DOM
  // through the store and Week's re-render, which lands a pass later than this
  // component's own state update, so the input is not there the first time
  // this runs; it is retried frame by frame for a moment.
  useEffect(() => {
    if (focusBlockId === null) return undefined;
    let attempts = 0;
    let frame;
    const tryFocus = () => {
      const input = blockTitleInput(focusBlockId);
      if (input) {
        input.focus();
        setFocusBlockId(null);
      } else if (attempts < 20) {
        attempts += 1;
        frame = requestAnimationFrame(tryFocus);
      } else {
        setFocusBlockId(null);
      }
    };
    tryFocus();
    return () => cancelAnimationFrame(frame);
  }, [focusBlockId]);

  const openPicker = () => {
    setFilter('');
    setOpen(true);
    dispatch(fetchWizardBlockCatalog(course.slug));
  };

  const cancel = () => {
    setOpen(false);
    triggerRef.current?.focus();
  };

  // Escape closes the picker from anywhere inside it, as the notes panel does.
  useEffect(() => {
    if (!open) return undefined;
    const onKeyDown = (event) => {
      if (event.key === 'Escape') cancel();
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [open]);

  const add = (entry) => {
    const { tempId } = dispatch(addWizardBlock(weekId, entry));
    setOpen(false);
    setFocusBlockId(tempId);
  };

  const needle = filter.trim().toLowerCase();
  const shown = needle
    ? catalog.filter(entry => (entry.title || '').toLowerCase().includes(needle))
    : catalog;

  // Grouped by the week the wizard would have placed the block in, which is the
  // order an admin reading the timeline expects to find them in.
  const weeks = [...new Set(shown.map(entry => entry.week))].sort((a, b) => a - b);

  // The button stays mounted while the picker is open so that focus has
  // somewhere to return to when it closes.
  return (
    <>
      <button
        type="button"
        className="pull-right week__add-wizard-block"
        onClick={openPicker}
        aria-describedby={describedBy}
        ref={triggerRef}
      >
        {I18n.t('timeline.add_standard_block')}
      </button>
      {open && (
        <Modal modalClass="add-wizard-block" ariaLabelledBy="add-wizard-block-title">
          <div className="add-wizard-block__panel">
            <h2 id="add-wizard-block-title">{I18n.t('timeline.standard_blocks')}</h2>
            <input
              className="add-wizard-block__filter"
              type="text"
              value={filter}
              onChange={e => setFilter(e.target.value)}
              placeholder={I18n.t('timeline.standard_block_filter')}
              aria-label={I18n.t('timeline.standard_block_filter')}
              ref={filterRef}
            />
            {loading && catalog.length === 0 && <Loading />}
            {/* A live region, always present, so the count is announced as the
                filter narrows it. */}
            <p className="add-wizard-block__count muted" role="status">
              {catalog.length > 0 && I18n.t('articles.articles_shown', {
                count: shown.length, total: catalog.length
              })}
            </p>
            {needle && catalog.length > 0 && shown.length === 0 && (
              <p className="muted">{I18n.t('application.no_results', { query: filter.trim() })}</p>
            )}
            {weeks.map(week => (
              <section key={`wizard-week-${week}`} className="add-wizard-block__week">
                <h3>{I18n.t('timeline.week_number', { number: week })}</h3>
                <ul className="list-unstyled">
                  {shown.filter(entry => entry.week === week).map(entry => (
                    <WizardBlockRow key={entry.id} entry={entry} onAdd={add} />
                  ))}
                </ul>
              </section>
            ))}
            <div className="add-wizard-block__actions">
              <button type="button" className="button" onClick={cancel}>
                {I18n.t('application.cancel')}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </>
  );
};

AddWizardBlock.propTypes = {
  course: PropTypes.object.isRequired,
  weekId: PropTypes.number.isRequired,
  // Id of an element describing which week the button belongs to.
  describedBy: PropTypes.string
};

export default AddWizardBlock;
