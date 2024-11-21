import React from 'react';
import PropTypes from 'prop-types';
import DiffViewer from './diff_viewer.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { formatDateWithTime } from '../../utils/date_utils.js';
import { trunc } from '../../utils/strings.js';
import withRouter from '@components/util/withRouter.jsx';

const Revision = ({ revision, index, wikidataLabel, course, setSelectedIndex, lastIndex, selectedIndex, student, router }) => {
  const ratingClass = `rating ${revision.rating}`;
  const ratingMobileClass = `${ratingClass} tablet-only`;
  const formattedTitle = CourseUtils.formattedArticleTitle({ title: revision.title, project: revision.wiki.project, language: revision.wiki.language }, course.home_wiki, wikidataLabel);
  const subtitle = wikidataLabel ? `(${CourseUtils.removeNamespace(revision.title)})` : '';
  const isWikipedia = revision.wiki.project === 'wikipedia';
  const showRealName = student.real_name;

  const openStudentDetails = () => {
    const url = `/courses/${course.slug}/students/articles/${encodeURIComponent(student.username)}`;
    router.navigate(url);
  };
  return (
    <tr className="revision">
      <td className="tooltip-trigger desktop-only-tc">
        {isWikipedia && <p className="rating_num hidden">{revision.rating_num}</p>}
        {isWikipedia && <div className={ratingClass}><p>{revision.pretty_rating || '-'}</p></div>}
        {isWikipedia && <div className="tooltip dark">
          <p>{I18n.t(`articles.rating_docs.${revision.rating || '?'}`, { class: revision.rating || '' })}</p>
          {/* eslint-disable-next-line */}
        </div>}
      </td>
      <td>
        {isWikipedia && <div className={ratingMobileClass}><p>{revision.pretty_rating || '-'}</p></div>}
        <a href={revision.article_url} target="_blank" className="inline"><p className="title">{formattedTitle}&nbsp;<small>{subtitle}</small></p></a>
      </td>
      <td className="desktop-only-tc">
        {showRealName ? (
          <span>
            <strong>{trunc(student.real_name)}</strong>&nbsp;
            (
            <a
              onClick={openStudentDetails} style={{
                cursor: 'pointer'
              }}
            >
              {revision.revisor}
            </a>
            )
          </span>
        ) : (
          <span>
            <a
              onClick={openStudentDetails} style={{
                cursor: 'pointer'
              }}
            >
              {revision.revisor}
            </a>
          </span>
        )}
      </td>
      <td className="desktop-only-tc">{revision.characters}</td>
      <td className="desktop-only-tc">{revision.references_added}</td>
      <td className="desktop-only-tc date"><a href={revision.url}>{formatDateWithTime(revision.date)}</a></td>
      <td>
        <DiffViewer
          index={index}
          revision={revision}
          editors={[revision.revisor]}
          articleTitle={revision.title}
          setSelectedIndex={setSelectedIndex}
          lastIndex={lastIndex}
          selectedIndex={selectedIndex}
        />
      </td>
    </tr>
  );
};

Revision.propTypes = {
  revision: PropTypes.object,
  index: PropTypes.number,
  wikidataLabel: PropTypes.string,
  course: PropTypes.object,
  setSelectedIndex: PropTypes.func,
  lastIndex: PropTypes.number,
  selectedIndex: PropTypes.number,
  student: PropTypes.object
};

export default withRouter(Revision);
