import React, { useEffect, useState } from 'react';
import SelectableBox from '../../common/selectable_box';
import { useDispatch, useSelector } from 'react-redux';
import { UPDATE_PETSCAN_IDS } from '../../../constants/scoping_methods';
import CreatableSelect from 'react-select/creatable';
import PetScanQueryBuilder from './petscan_query_builder';

const PetScanScoping = ({ hideDescription }) => {
  const [choosenOption, setChoosenOption] = useState();
  const [inputValue, setInputValue] = React.useState('');
  const petscanIDs = useSelector(state => state.scopingMethods.petscan.psids);
  const dispatch = useDispatch();
  useEffect(() => {
    if (choosenOption === undefined) {
      hideDescription(false);
    } else {
      hideDescription(true);
    }
  }, [choosenOption]);

  const handleKeyDown = async (event) => {
    if (!inputValue) return;
    switch (event.key) {
      case 'Enter':
      case 'Tab':
        if (isNaN(inputValue)) {
          return;
        }
        dispatch({
          type: UPDATE_PETSCAN_IDS,
          psids: petscanIDs.concat({
            label: inputValue,
            value: inputValue,
          }),
        });
        setInputValue('');
        event.preventDefault();
        break;
      default:
    }
  };

  if (!choosenOption) {
    return (
      <div>
        <SelectableBox
          heading={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_have_psid_title'
          )}
          description={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_have_psid_desc'
          )}
          onClick={() => setChoosenOption('HAVE_ID')}
        />
        <SelectableBox
          heading={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_not_have_psid_title'
          )}
          description={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_not_have_psid_desc'
          )}
          onClick={() => setChoosenOption('NO_ID')}
        />
      </div>
    );
  }
  if (choosenOption === 'HAVE_ID') {
    return (
      <div className="scoping-method-petscan form-group">
        <label htmlFor="petscan-ids">Enter PetScan IDs</label>
        <CreatableSelect
          inputValue={inputValue}
          isClearable
          isMulti
          menuIsOpen={false}
          onChange={psids => dispatch({ type: UPDATE_PETSCAN_IDS, psids })}
          onInputChange={newValue => !isNaN(newValue) && setInputValue(newValue)}
          onKeyDown={handleKeyDown}
          placeholder="Type something and press enter..."
          value={petscanIDs}
          className="react-select-container"
          id="petscan-psids"
        />
        <a href="https://petscan.wmflabs.org/" target="_blank">
          {I18n.t('courses_generic.creator.scoping_methods.petscan_create_psid')}
        </a>
      </div>
    );
  }
  return <PetScanQueryBuilder />;
};

export default PetScanScoping;
