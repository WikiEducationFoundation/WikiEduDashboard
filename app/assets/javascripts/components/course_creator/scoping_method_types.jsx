import { useDispatch, useSelector } from 'react-redux';
import SelectableBox from '../common/selectable_box';
import React from 'react';
import { allScopingMethods, getScopingMethodLabel, getShortDescription } from '@components/util/scoping_methods';

const ScopingMethodTypes = () => {
  const dispatch = useDispatch();
  const selected = useSelector(state => state.scopingMethods.selected);

  const toggleScopingMethod = (methodName) => {
    dispatch({ type: 'TOGGLE_SCOPING_METHOD', method: methodName });
  };



  return (
    <div className="scoping-method-types">
      {allScopingMethods.map(method => (
        <SelectableBox
          key={method}
          description={getShortDescription(method)}
          heading={getScopingMethodLabel(method)}
          style={{ width: '90%', margin: 0 }}
          onClick={toggleScopingMethod.bind(null, method)}
          selected={selected.includes(method)}
        />
      ))}
    </div>
  );
};

export default ScopingMethodTypes;
