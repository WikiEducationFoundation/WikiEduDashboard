import React from 'react';
import PopoverButton from '../high_order/popover_button.jsx';
import CohortStore from '../../stores/cohort_store.js';

const cohortIsNew = cohort => CohortStore.getFiltered({ title: cohort }).length === 0;

const cohorts = (props, remove) =>
  props.cohorts.map(cohort => {
    let removeButton = (
      <button className="button border plus" onClick={remove.bind(null, cohort.id)}>-</button>
    );
    return (
      <tr key={`${cohort.id}_cohort`}>
        <td>{cohort.title}{removeButton}</td>
      </tr>
    );
  })
;

cohorts.propTypes = {
  cohorts: React.PropTypes.array
};

export default PopoverButton('cohort', 'title', CohortStore, cohortIsNew, cohorts, true);
