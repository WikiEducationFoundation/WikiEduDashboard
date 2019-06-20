import React from 'react';
import SelectedWikiOption from '../common/selected_wiki_option';

const NewAssignmentInput = ({
  language, project, title,
  assign, handleChangeTitle, handleWikiChange
}) => (
  <form onSubmit={assign}>
    <input
      placeholder={I18n.t('articles.title_example')}
      value={title}
      onSubmit={assign}
      onChange={handleChangeTitle}
    />
    <button className="button border" type="submit">{I18n.t('assignments.label')}</button>
    <SelectedWikiOption
      language={language}
      project={project}
      handleWikiChange={handleWikiChange}
    />
  </form>
);

export default NewAssignmentInput;
