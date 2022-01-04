import React from 'react';
import SelectedWikiOption from '../common/selected_wiki_option';
import ArticleUtils from '../../utils/article_utils';

const NewAssignmentInput = ({
  language, project, title,
  assign, handleChangeTitle, handleWikiChange, trackedWikis
}) => (
  <form onSubmit={assign}>
    <input
      placeholder={ArticleUtils.I18n('title_example', project)}
      value={title}
      onSubmit={assign}
      onChange={handleChangeTitle}
    />
    <button className="button border" type="submit">{I18n.t('assignments.label')}</button>
    <SelectedWikiOption
      language={language}
      project={project}
      handleWikiChange={handleWikiChange}
      trackedWikis={trackedWikis}
    />
  </form>
);

export default NewAssignmentInput;
