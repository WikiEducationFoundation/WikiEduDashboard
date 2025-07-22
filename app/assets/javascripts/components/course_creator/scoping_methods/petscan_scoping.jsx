import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { UPDATE_PETSCAN_IDS } from '../../../constants/scoping_methods';
import CreatableSelect from 'react-select/creatable';
import WikiSelect from '../../common/wiki_select';
import { formatCategoryName } from '../../util/scoping_methods';

const PETSCAN_URL_PATTERN = /https:\/\/petscan.wmcloud.org\/\?psid=(\d+)/;
const PetScanScoping = () => {
  const [inputValue, setInputValue] = React.useState('');
  const petscanIDs = useSelector(state => state.scopingMethods.petscan.psids);
  const dispatch = useDispatch();
  const home_wiki = useSelector(state => state.course.home_wiki);
  const [currentWiki, setCurrentWiki] = useState(home_wiki);

  const handleAddId = (value) => {
    if (isNaN(value)) {
      return;
    }
    dispatch({
      type: UPDATE_PETSCAN_IDS,
      psids: petscanIDs.concat({
        label: formatCategoryName({
          category: value,
          wiki: currentWiki,
        }),
        value: {
          title: value,
          wiki: currentWiki,
        },
      }),
    });
    setInputValue('');
  };

  const handleKeyDown = async (event) => {
    if (!inputValue) return;
    switch (event.key) {
      case 'Enter':
      case 'Tab':
      case ',':
        handleAddId(inputValue);
        event.preventDefault();
        break;
      default:
    }
  };

  const onChangeHandler = (newValue, data) => {
    if (data.action !== 'input-change') return;
    if (!newValue) {
      setInputValue('');
      return;
    }
    if (newValue.match(PETSCAN_URL_PATTERN)) {
      const psid = newValue.match(PETSCAN_URL_PATTERN)[1];
      dispatch({
        type: UPDATE_PETSCAN_IDS,
        psids: petscanIDs.concat({
          label: formatCategoryName({
            category: psid,
            wiki: currentWiki,
          }),
          value: {
            title: psid,
            wiki: currentWiki,
          },
        }),
      });
      setInputValue('');
    } else if (!isNaN(newValue)) {
      setInputValue(newValue);
    }
  };

  const onBlurHandler = () => {
    if (!inputValue) {
      setInputValue('');
      return;
    }
    handleAddId(inputValue);
  };

  return (
    <div className="scoping-method-petscan form-group">
      <label htmlFor="petscan-ids">Enter PetScan IDs/URLs</label>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'minmax(400px, 2fr) minmax(200px, 1fr)',
        gap: '1em',
      }}
      >
        <CreatableSelect
          inputValue={inputValue}
          isClearable
          isMulti
          menuIsOpen={false}
          onChange={psids => dispatch({ type: UPDATE_PETSCAN_IDS, psids })}
          onInputChange={onChangeHandler}
          onKeyDown={handleKeyDown}
          placeholder="Type something and press enter. Or enter a comma-separated list"
          value={petscanIDs}
          className="react-select-container"
          id="petscan-psids"
          onBlur={onBlurHandler}
        />
        <WikiSelect
          id="petscan-wiki-select-input"
          label={I18n.t('articles.wiki')}
          homeWiki={home_wiki}
          onChange={wiki => setCurrentWiki(wiki.value)}
        />
      </div>
      <a href="https://petscan.wmcloud.org/" target="_blank">
        {I18n.t('courses_generic.creator.scoping_methods.petscan_create_psid')}
      </a>
    </div>
  );
};

export default PetScanScoping;
