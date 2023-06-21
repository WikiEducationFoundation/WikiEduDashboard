import React from 'react';
import { getAvailableNamespaces } from '../../util/scoping_methods';
import Select from 'react-select';
import { useDispatch } from 'react-redux';

const AutocompleteNamespacesInput = ({ label, actionType, initial }) => {
  const dispatch = useDispatch();

  const updateNamespaces = (namespaces) => {
    dispatch({
      type: actionType,
      namespaces,
    });
  };

  return (
    <>
      <label htmlFor="namespaces">{label}</label>
      <Select
        isMulti
        name="namespaces"
        options={getAvailableNamespaces()}
        onChange={updateNamespaces}
        defaultValue={initial}
      />
    </>
  );
};

export default AutocompleteNamespacesInput;
