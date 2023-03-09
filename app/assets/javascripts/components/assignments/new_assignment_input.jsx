import React from 'react';
import SelectedWikiOption from '../common/selected_wiki_option';
import ArticleUtils from '../../utils/article_utils';

const NewAssignmentInput = ({
  language, project, title,
  assign, handleChangeTitle, handleWikiChange, trackedWikis
}) => (
  <form
    onSubmit={assign}
    style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'flex-end',
      gap: '5px'
    }}
  >
    <textarea
      placeholder={ArticleUtils.I18n('title_example', project)}
      value={title}
      onSubmit={assign}
      onChange={handleChangeTitle}
      style={{
        padding: '0',
        width: '100%',
      }}
    />
    <button
      className="button border"
      type="submit"
      style={{
        width: 'max-content',
      }}
    >
      {I18n.t('assignments.label')}
    </button>
    <SelectedWikiOption
      language={language}
      project={project}
      handleWikiChange={handleWikiChange}
      trackedWikis={trackedWikis}
    />
  </form>
);

export default NewAssignmentInput;
