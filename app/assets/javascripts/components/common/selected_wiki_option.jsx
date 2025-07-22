import React, { useState } from 'react';
import WikiSelect from '../common/wiki_select.jsx';
import selectStyles from '../../styles/select';

// Wrapper component for WikiSelect. This allows you to click the "Change"
// link in order to change the selected wiki.
const SelectedWikiOption = (props) => {
  const [show, setShow] = useState(false);
  const handleShowOptions = (e) => {
    e.preventDefault();
    setShow(true);
  };

  const { language, project, trackedWikis } = props;
  if (show) {
    return (
      <div className="wiki-select">
        <WikiSelect
          id="wiki-select-input"
          label={I18n.t('articles.wiki')}
          wikis={[{ language, project }]}
          onChange={props.handleWikiChange}
          options={trackedWikis}
          multi={false}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
  }

  return (
    <div className="small-block-link">
      {language}.{project}.org <a href="#" onClick={handleShowOptions}>({I18n.t('application.change')})</a>
    </div>
  );
};

export default SelectedWikiOption;
