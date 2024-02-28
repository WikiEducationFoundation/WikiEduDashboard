import React, { useState } from 'react';
import TextInput from '../../common/text_input';
import { updateImpactStats } from '../../../actions/settings_actions';
import { connect } from 'react-redux';

const ImpactStatsForm = (props) => {
    const [stats, setStats] = useState({});

    const handleChange = (key, value) => {
        setStats({ ...stats, [key]: value });
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        props.updateImpactStats(stats);
        props.handlePopoverClose(e);
    };

    return (
      <tr>
        <td>
          <form onSubmit={handleSubmit}>
            <TextInput
              id="wiki_edu_courses"
              editable
              onChange={handleChange}
              value={stats.wiki_edu_courses}
              value_key="wiki_edu_courses"
              type="text"
              label="Wiki education courses"
            />
            <TextInput
              id="students"
              editable
              onChange={handleChange}
              value={stats.students}
              value_key="students"
              type="text"
              label="Students"
            />
            <TextInput
              id="worked_articles"
              editable
              onChange={handleChange}
              value={stats.worked_articles}
              value_key="worked_articles"
              type="text"
              label="Articles worked on"
            />
            <TextInput
              id="added_words"
              editable
              onChange={handleChange}
              value={stats.added_words}
              value_key="added_words"
              type="text"
              label="Added words (in millions)"
            />
            <TextInput
              id="total_pages"
              editable
              onChange={handleChange}
              value={stats.total_pages}
              value_key="total_pages"
              type="text"
              label="Total pages"
            />
            <TextInput
              id="volumes"
              editable
              onChange={handleChange}
              value={stats.volumes}
              value_key="volumes"
              type="text"
              label="Volumes"
            />
            <TextInput
              id="article_views"
              editable
              onChange={handleChange}
              value={stats.article_views}
              value_key="article_views"
              type="text"
              label="Article views (in millions)"
            />
            <TextInput
              id="universities"
              editable
              onChange={handleChange}
              value={stats.universities}
              value_key="universities"
              type="text"
              label="Universities"
            />
            <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
          </form>
        </td>
      </tr>
    );
};

const mapDispatchToProps = {
    updateImpactStats,
};

export default connect(null, mapDispatchToProps)(ImpactStatsForm);
