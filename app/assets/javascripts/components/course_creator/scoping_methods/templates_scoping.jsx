import React, { useState } from 'react';
import TemplatesAutoCompleteInput from '../../common/ScopingMethods/autocomplete_templates_input';
import { UPDATE_TEMPLATES } from '../../../constants/scoping_methods';
import { useSelector } from 'react-redux';
import WikiSelect from '../../common/wiki_select';

const TemplatesScoping = () => {
  const templates = useSelector(state => state.scopingMethods.templates.include);
  const home_wiki = useSelector(state => state.course.home_wiki);
  const [currentWiki, setCurrentWiki] = useState(home_wiki);
  return (
    <div>
      <div
        className="form-group" style={{
        display: 'grid',
        gridTemplateColumns: 'minmax(400px, 2fr) minmax(200px, 1fr)',
        alignItems: 'end',
        gap: '1em'
      }}
      >
        <TemplatesAutoCompleteInput
          label={
            <div className="tooltip-trigger">
              <label htmlFor="templates">Templates To Include</label>
              <span className="tooltip-indicator"/>
              <div className="tooltip dark">
                {I18n.t('courses_generic.creator.scoping_methods.templates_include_OR')}
              </div>
            </div>
        } actionType={UPDATE_TEMPLATES} initial={templates} wiki={currentWiki}
        />
        <WikiSelect homeWiki={home_wiki} onChange={wiki => setCurrentWiki(wiki.value)}/>
      </div>
    </div>
  );
};

export default TemplatesScoping;
