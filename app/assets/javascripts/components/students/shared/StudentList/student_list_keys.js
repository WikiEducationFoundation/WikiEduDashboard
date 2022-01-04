import ArticleUtils from '../../../../utils/article_utils';

const charactersAddedKey = (project) => {
  return {
    label: I18n.t(`users.${ArticleUtils.projectSuffix(project, 'chars_added')}`),
    desktop_only: true,
    sortable: true,
    info_key: 'users.character_doc'
  };
};

const wordsAddedKey = {
  label: I18n.t('users.words_added'),
  desktop_only: true,
  sortable: true,
  info_key: 'users.word_count_doc'
};

const studentListKeys = (course) => {
  const contentAddedKey = course.home_wiki_bytes_per_word ? wordsAddedKey : charactersAddedKey(course.home_wiki.project);

  return {
    username: {
      label: I18n.t('users.name'),
      desktop_only: false,
      sortable: true,
    },
    assignment_title: {
      label: I18n.t(`users.${ArticleUtils.projectSuffix(course.home_wiki.project, 'assigned')}`),
      desktop_only: true,
      sortable: false
    },
    reviewing_title: {
      label: I18n.t('users.reviewing'),
      desktop_only: true,
      sortable: false
    },
    recent_revisions: {
      label: I18n.t('users.recent_revisions'),
      desktop_only: true,
      sortable: true,
      info_key: 'users.revisions_doc'
    },
    character_sum_ms: contentAddedKey,
    references_count: {
      label: I18n.t('users.references_count'),
      desktop_only: true,
      sortable: true,
      info_key: `metrics.${ArticleUtils.projectSuffix(course.home_wiki.project, 'references_doc')}`
    },
    total_uploads: {
      label: I18n.t('users.total_uploads'),
      desktop_only: true,
      sortable: true,
      info_key: 'users.uploads_doc'
    }
  };
};

export default studentListKeys;
