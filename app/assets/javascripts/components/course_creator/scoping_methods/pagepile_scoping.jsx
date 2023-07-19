import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CreatableSelect from 'react-select/creatable';
import { UPDATE_PAGEPILE_IDS } from '../../../constants/scoping_methods';
import WikiSelect from '../../common/wiki_select';

const PAGEPILE_URL_PATTERN = /https:\/\/pagepile.toolforge.org\/api.php\?id=(\d+).+/;
const PagePileScoping = () => {
  const [inputValue, setInputValue] = useState('');
  const pagePileIds = useSelector(state => state.scopingMethods.pagepile.ids);

  const dispatch = useDispatch();
  const home_wiki = useSelector(state => state.course.home_wiki);
  const [currentWiki, setCurrentWiki] = useState(home_wiki);
  const handleAddId = (value) => {
    if (isNaN(value)) {
      return;
    }
    dispatch({
      type: UPDATE_PAGEPILE_IDS,
      ids: pagePileIds.concat({
        label: value,
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
    if (newValue.match(PAGEPILE_URL_PATTERN)) {
      const pagepileID = newValue.match(PAGEPILE_URL_PATTERN)[1];
      dispatch({
        type: UPDATE_PAGEPILE_IDS,
        ids: pagePileIds.concat({
          label: pagepileID,
          value: {
            title: pagepileID,
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
      <label htmlFor="pagepile-ids">Enter PagePile IDs/URLs</label>
      <div
        style={{
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
          onChange={ids => dispatch({ type: UPDATE_PAGEPILE_IDS, ids })}
          onInputChange={onChangeHandler}
          onKeyDown={handleKeyDown}
          placeholder="Type something and press enter. Or enter a comma-separated list"
          value={pagePileIds}
          className="react-select-container"
          id="pagepile-ids"
          onBlur={onBlurHandler}
        />
        <WikiSelect
          homeWiki={home_wiki}
          onChange={wiki => setCurrentWiki(wiki.value)}
        />

      </div>
      <a href="https://pagepile.toolforge.org/" target="_blank">
        {I18n.t('courses_generic.creator.scoping_methods.pagepile_create_id')}
      </a>
    </div>
  );
};

export default PagePileScoping;
