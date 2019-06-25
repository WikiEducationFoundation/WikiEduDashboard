/* eslint-disable */

const i18n = (messageKey, prefix, defaultPrefix = 'courses') => {
  return I18n.t(`${prefix}.${messageKey}`, {
    defaults: [{ scope: `${defaultPrefix}.${messageKey}` }]
  });
};

const EmbedCourseStats = () => {
  let viewData;

  let contentCount;
  if (course.home_wiki.language === 'en') {
    contentCount = (
      <div className="stat-display__stat" id="word-count">
        <div className="stat-display__value">{course.word_count}</div>
        <small>{I18n.t('metrics.word_count')}</small>
      </div>
    );
  } else {
    contentCount = (
      <div className="stat-display__stat" id="bytes-added">
        <div className="stat-display__value">{course.character_sum_human}</div>
        <small>{I18n.t('metrics.bytes_added')}</small>
      </div>
    );
  }

  let refCount;
  if (course.references_count !== 0) {
    refCount = (
      <div className="stat-display__stat" id="references-added">
        <div className={valueClass('references_count')}>{course.references_count}</div>
        <small>{I18n.t('metrics.references_count')}</small>
      </div>
    );
  }

  if (course.upload_usages_count === undefined) {
    return <div className="stat-display" />;
  }
  if (course.view_count === '0' && course.edited_count !== '0') {
    viewData = (
      <div className="stat-display__data">
        {I18n.t('metrics.view_data_unavailable')}
      </div>
    );
  } else {
    viewData = (
      <div className="stat-display__value">
        {course.view_count}
      </div>
    );
  }

  return (
    <div className="stat-display">
      <div className="stat-display__stat" id="articles-created">
        <div className="stat-display__value">{course.created_count}</div>
        <small>{I18n.t('metrics.articles_created')}</small>
      </div>
      <div className="stat-display__stat" id="articles-edited">
        <div className="stat-display__value">{course.edited_count}</div>
        <small>{I18n.t('metrics.articles_edited')}</small>
      </div>
      <div className="stat-display__stat" id="total-edits">
        <div className="stat-display__value">{course.edit_count}</div>
        <small>{I18n.t('metrics.edit_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="student-editors">
        <div className="stat-display__value">
          {course.student_count}
        </div>
        <small>{i18n('student_editors', course.string_prefix)}</small>
      </div>
      {contentCount}
      {refCount}
      <div className="stat-display__stat" id="view-count">
        {viewData}
        <small>{I18n.t('metrics.view_count_description')}</small>
      </div>
      <div className="stat-display__stat tooltip-trigger" id="upload-count">
        <div className="stat-display__value">
          {course.upload_count}
        </div>
        <small>{I18n.t('metrics.upload_count')}</small>
      </div>
    </div>
  );
};

ReactDOM.render(<EmbedCourseStats />, document.getElementById('root'));
