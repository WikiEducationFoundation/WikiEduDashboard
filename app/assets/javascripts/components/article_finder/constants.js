export const table_keys = {
  relevanceIndex: {
    label: I18n.t('article_finder.relevanceIndex'),
    desktop_only: false,
  },
  title: {
    label: I18n.t('articles.title'),
    desktop_only: false,
  },
  grade: {
    label: I18n.t('article_finder.page_assessment_class'),
    desktop_only: false,
    sortable: true,
  },
  revScore: {
    label: I18n.t('article_finder.completeness_estimate'),
    desktop_only: false,
    sortable: true,
  },
  pageviews: {
    label: I18n.t('article_finder.average_views'),
    desktop_only: false,
    sortable: true,
  },
  tools: {
    label: I18n.t('article_finder.tools'),
    desktop_only: false,
    sortable: false,
  },
};
