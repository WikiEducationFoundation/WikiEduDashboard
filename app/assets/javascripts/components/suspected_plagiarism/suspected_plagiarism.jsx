import React from 'react';
import PropTypes from 'prop-types';
import { formatWithTime } from '../../utils/date_utils';

const SuspectedPlagiarism = ({ revision }) => {
  return (
    <tr className="revision">
      <td>
        <a href={revision.article_url} target="_blank" className="inline"><p className="title">{revision.title}</p></a>
      </td>
      <td className="desktop-only-tc">{revision.username}</td>
      <td className="date"><a href={revision.url}>{formatWithTime(revision.date)}</a></td>
      <td className="desktop-only-tc"><a href={revision.report_url} target="_blank">Report</a></td>
    </tr>
  );
};

SuspectedPlagiarism.propTypes = {
  revision: PropTypes.object,
};

export default SuspectedPlagiarism;
