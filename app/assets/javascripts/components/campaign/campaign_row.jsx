import React, { useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import { startDownload } from '../../actions/download_actions.js';

const CampaignExportModal = ({ campaign }) => {
  const dispatch = useDispatch();
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (!show) { return; }

    const handleEscape = (event) => {
      if (event.key === 'Escape') { setShow(false); }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [show]);

  const exportOptions = [
    { id: `${campaign.slug}-students`, href: `/campaigns/${campaign.slug}/students.csv`, dataLabel: I18n.t('campaign.students_small') },
    { id: `${campaign.slug}-students-by-course`, href: `/campaigns/${campaign.slug}/students.csv?course=true`, dataLabel: I18n.t('campaign.student_course') },
    { id: `${campaign.slug}-instructors-by-course`, href: `/campaigns/${campaign.slug}/instructors.csv?course=true`, dataLabel: I18n.t('campaign.instructors_course') },
    { id: `${campaign.slug}-courses`, href: `/campaigns/${campaign.slug}/courses.csv`, dataLabel: I18n.t('campaign.course_data') },
    { id: `${campaign.slug}-articles`, href: `/campaigns/${campaign.slug}/articles_csv.csv`, dataLabel: I18n.t('campaign.pages_edited_small') },
    { id: `${campaign.slug}-all`, href: `/campaigns/${campaign.slug}/all_csv`, dataLabel: I18n.t('campaign.all_data') },
  ];

  const handleDownload = (option, event) => {
    event.preventDefault();
    dispatch(startDownload({
      ...option,
      label: `${campaign.title} — ${option.dataLabel}`
    }));
    alert(I18n.t('campaign.data_download_generating'));
    setShow(false);
  };

  if (!show) {
    return (
      <button onClick={() => setShow(true)} className="button dark small campaign-export-button">
        {I18n.t('campaign.export')}
      </button>
    );
  }

  return (
    <div className="basic-modal left campaign-export-modal">
      <button onClick={() => setShow(false)} className="pull-right button--clear small">
        &times;
      </button>
      <h2>{I18n.t('campaign.data_download_info')}</h2>
      <hr />
      {exportOptions.map(option => (
        <p key={option.id}>
          <a href={option.href} onClick={(e) => handleDownload(option, e)} className="button dark button--block">
            {option.dataLabel}
          </a>
        </p>
      ))}
    </div>
  );
};

const CampaignRow = ({ campaign }) => {
  return (
    <tr>
      <td className="table-link-cell title">
        <a href={`/campaigns/${campaign.slug}/overview`}>{campaign.title}</a>
      </td>
      <td className="table-link-cell num-courses-human text-center">{campaign.human_course_count}</td>
      <td className="table-link-cell articles-created-human text-center">{campaign.human_new_article_count}</td>
      <td className="table-link-cell articles-edited-human text-center">{campaign.human_article_count}</td>
      <td className="table-link-cell characters-human text-center">{campaign.human_word_count}</td>
      <td className="table-link-cell references-human text-center">{campaign.human_references_count}</td>
      <td className="table-link-cell views-human text-center">{campaign.human_view_sum}</td>
      <td className="table-link-cell students text-center">{campaign.user_count}</td>
      {!Features.wikiEd && (
        <td className="table-link-cell creation-date text-center">{campaign.creation_date}</td>
      )}
      <td className="csv">
        <CampaignExportModal campaign={campaign} />
      </td>
    </tr>
  );
};

export default CampaignRow;
