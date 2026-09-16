import React, { useState } from 'react';
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
const AddWizardBlock = ({ course, weekId }) => {
  const dispatch = useDispatch();
  const { catalog, loading, loaded } = useSelector(state => state.wizardBlocks);
  const [open, setOpen] = useState(false);
  const [filter, setFilter] = useState('');

  const openPicker = () => {
    setOpen(true);
    if (!loaded && !loading) dispatch(fetchWizardBlockCatalog(course.slug));
  };

  const add = (entry) => {
    dispatch(addWizardBlock(weekId, entry));
    setOpen(false);
  };

  if (!open) {
    return (
      <button type="button" className="pull-right week__add-wizard-block" onClick={openPicker}>
        {I18n.t('timeline.add_standard_block')}
      </button>
    );
  }

  const needle = filter.trim().toLowerCase();
  const shown = needle
    ? catalog.filter(entry => (entry.title || '').toLowerCase().includes(needle))
    : catalog;

  // Grouped by the week the wizard would have placed the block in, which is the
  // order an admin reading the timeline expects to find them in.
  const weeks = [...new Set(shown.map(entry => entry.week))].sort((a, b) => a - b);

  return (
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
        />
        {loading && <Loading />}
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
          <button type="button" className="button" onClick={() => setOpen(false)}>
            {I18n.t('application.cancel')}
          </button>
        </div>
      </div>
    </Modal>
  );
};

AddWizardBlock.propTypes = {
  course: PropTypes.object.isRequired,
  weekId: PropTypes.number.isRequired
};

export default AddWizardBlock;
