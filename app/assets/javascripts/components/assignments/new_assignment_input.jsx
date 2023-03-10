import React from 'react';
import SelectedWikiOption from '../common/selected_wiki_option';

const NewAssignmentInput = ({
  language, project, title,
  assign, handleChangeTitle, handleWikiChange, trackedWikis
}) => {
  const articles = title.split('\n').length;
  const multipleArticles = articles > 1;
  return (
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
        placeholder={I18n.t('assignments.add_available_placeholder')}
        value={title}
        onSubmit={assign}
        onChange={handleChangeTitle}
        rows={`${articles <= 1 ? 1 : 3}`}
        style={{
        padding: '10px',
        width: '100%',
        minWidth: '275px',
      }}
      />
      <button
        className="button border"
        type="submit"
        style={{
        width: 'max-content',
      }}
      >
        {multipleArticles ? I18n.t('assignments.label_all') : I18n.t('assignments.label')}
      </button>
      <SelectedWikiOption
        language={language}
        project={project}
        handleWikiChange={handleWikiChange}
        trackedWikis={trackedWikis}
      />
    </form>
);
};

export default NewAssignmentInput;
