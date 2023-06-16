import React, { useEffect, useState } from 'react';
import SelectableBox from '../../common/selectable_box';
import { useDispatch, useSelector } from 'react-redux';
import { UPDATE_PETSCAN_IDS, UPDATE_PETSCAN_ON_HOME_PAGE } from '../../../constants/scoping_methods';
import CreatableSelect from 'react-select/creatable';
import PetScanQueryBuilder from './petscan_query_builder';

const PetScanScoping = ({ hideDescription }) => {
  const [choosenOption, setChoosenOption] = useState();
  const [inputValue, setInputValue] = React.useState('');
  const petscanIDs = useSelector(state => state.scopingMethods.petscan.psids);
  const isOnHomePage = useSelector(state => state.scopingMethods.petscan.on_home_page);
  const dispatch = useDispatch();

  const dispatchNotOnHomePage = () => {
    dispatch({
      type: UPDATE_PETSCAN_ON_HOME_PAGE,
      on_home_page: false
    });
  };

  useEffect(() => {
    if (isOnHomePage) {
      hideDescription(false);
    } else {
      hideDescription(true);
    }
  }, [isOnHomePage]);


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

  if (isOnHomePage) {
    return (
      <div>
        <SelectableBox
          heading={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_not_have_psid_title'
          )}
          description={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_not_have_psid_desc'
          )}
          onClick={() => {
            setChoosenOption('NO_ID');
            dispatchNotOnHomePage();
            }
          }
        />
        <SelectableBox
          heading={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_have_psid_title'
          )}
          description={I18n.t(
            'courses_generic.creator.scoping_methods.petscan_have_psid_desc'
          )}
          onClick={() => {
            setChoosenOption('HAVE_ID');
            dispatchNotOnHomePage();
            }
          }
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
