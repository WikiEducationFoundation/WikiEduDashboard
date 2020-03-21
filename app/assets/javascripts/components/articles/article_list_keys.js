const contentAddedKey = (course) => {
  if (course.home_wiki_bytes_per_word) {
    return {
      label: I18n.t('metrics.word_count'),
      desktop_only: true,
      info_key: `${course.string_prefix}.word_count_doc`
    };
  }
  return {
    label: I18n.t('metrics.char_added'),
    desktop_only: true,
    info_key: 'articles.character_doc'
  };
};

const articleListKeys = (course) => {
  return {
    rating_num: {
      label: I18n.t('articles.rating'),
      desktop_only: true,
      info_key: 'articles.rating_doc'
    },
    title: {
      label: I18n.t('articles.title'),
      desktop_only: false
    },
    character_sum: contentAddedKey(course),
    references_count: {
      label: I18n.t('metrics.references_count'),
      desktop_only: true,
      info_key: 'metrics.references_doc'
    },
    view_count: {
      label: I18n.t('metrics.view'),
      desktop_only: true,
      info_key: 'articles.view_doc'
    },
    tools: {
      label: I18n.t('articles.tools'),
      desktop_only: false,
      sortable: false
    },
  };
};

export default articleListKeys;
