import React, { useEffect, useState } from 'react';

import { connect } from 'react-redux';
import { difference, uniq } from 'lodash-es';
import moment from 'moment';

import PropTypes from 'prop-types';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';
import selectStyles from '../../styles/single_select';

import { fetchSpecialUsers } from '../../actions/settings_actions';
import { fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { removeTag, fetchAllTags, addTag } from '../../actions/tag_actions';
import { addUser } from '../../actions/user_actions';
import { getCourseApprovalStaff } from '../../selectors';
import { STAFF_ROLE } from '../../constants';


const CourseApproval = (props) => {
  const [selectedWikiExpert, setSelectedWikiExpert] = useState({});
  const [selectedCampaigns, setSelectedCampaigns] = useState([]);
  const [selectedTags, setSelectedTags] = useState([]);
  const [createdTagOption, setCreatedTagOption] = useState([]);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    props.fetchSpecialUsers();
    props.fetchAllCampaigns();
    props.fetchAllTags();
  }, []);

  useEffect(() => {
    if (props.wikiEdStaff.length > 0) {
      const wikiExpert = props.wikiEdStaff.find(user => user.role === 'wikipedia_expert');
      const currentWikiExpert = props.wikiEdStaff.find(user => user.role === 'wikipedia_expert' && user.already_selected);

      setSelectedWikiExpert(
        (currentWikiExpert !== null && currentWikiExpert !== undefined)
          ? { value: currentWikiExpert.username, label: `${currentWikiExpert.username} (${currentWikiExpert.realname})` }
          : { value: wikiExpert.username, label: `${wikiExpert.username} (${wikiExpert.realname})` }
      );
    }

    if (props.allCampaigns.length > 0) {
      setDefaultCampaign();
    }

    if (props.tags.length > 0) {
      setSelectedTags(props.tags.map((tag) => {
        return { value: tag.tag, label: tag.tag };
      }));
    }
  }, [props.wikiEdStaff, props.allCampaigns, props.tags]);

  const setProgramManager = () => {
    const programManager = props.wikiEdStaff.find(user => user.role === 'classroom_program_manager');
    return {
      value: programManager.username,
      label: `${programManager.username} (${programManager.realname})`
    };
  };

  const setWikiExpertOptions = () => {
    const wikiExperts = props.wikiEdStaff.filter(user => user.role === 'wikipedia_expert');
    const options = wikiExperts.map((user) => {
      return {
        value: user.username,
        label: `${user.username} (${user.realname})`
      };
    });
    return options;
  };

  const setDefaultCampaign = () => {
    const start_date = props.course.start;
    const month = moment(start_date).month();
    const year = moment(start_date).year();

    let term;
    switch (month) {
      case 11:
        term = `spring_${year + 1}`;
        break;

      case 0: case 1: case 2: case 3:
        term = `spring_${year}`;
        break;

      case 4: case 5: case 6:
        term = `summer_${year}`;
        break;

      case 7: case 8: case 9: case 10:
        term = `fall_${year}`;
        break;

      default:
        term = '';
        break;
    }

    const defaultCampaign = props.allCampaigns.filter(campaign => campaign.slug === term);

    if (defaultCampaign.length > 0) {
      setSelectedCampaigns([{
        value: defaultCampaign[0].title,
        label: defaultCampaign[0].title
      }]);
    }
  };

  const handleWikiExpertChange = (selectedOption) => {
    return setSelectedWikiExpert(selectedOption);
  };

  const handleCampaignsChange = (selectedOptions) => {
    return setSelectedCampaigns(selectedOptions);
  };

  const handleTagChange = (selectedOption) => {
    // The value includes `__isNew__: true` if it's a user-created option.
    // In that case, we need to add it to the list of options, so that it shows up as selected.
    const isNew = selectedOption.__isNew__;
    if (isNew) {
      setCreatedTagOption([selectedOption]);
    }
    setSelectedTags(selectedOption);
  };


  const submitWikiEdStaff = (programManager, wikiExpert) => {
    const promises = [];
    // Only add the program manager, if they are not already assigned a staff role
    if (!programManager.already_selected) {
      const programManagerUserObject = {
        username: programManager.username,
        role: STAFF_ROLE,
        role_description: null,
        real_name: programManager.realname
      };
      promises.push(props.addUser(props.course.slug, { user: programManagerUserObject }));
    }

    // Only add the selected wiki expert, if they are not already assigned a staff role
    if (!wikiExpert.already_selected) {
      const wikiExpertUserObject = {
        username: wikiExpert.username,
        role: STAFF_ROLE,
        role_description: null,
        real_name: wikiExpert.realname
      };
      promises.push(props.addUser(props.course.slug, { user: wikiExpertUserObject }));
    }
    return promises;
  };

  const submitCampaigns = () => {
    const promises = [];
    if (selectedCampaigns.length > 0) {
      selectedCampaigns.forEach((campaign) => {
        promises.push(props.addCampaign(props.course.slug, campaign.value));
      });
    }
    return promises;
  };

  const submitTags = () => {
    const oldTags = props.tags.map(tag => tag.tag);
    const currentTags = selectedTags.map(tag => tag.value);

    const newTags = difference(currentTags, oldTags);
    const removedTags = difference(oldTags, currentTags);

    const promises = [];
    newTags.forEach((tag) => {
      promises.push(props.addTag(props.course.slug, tag));
    });
    removedTags.forEach((tag) => {
      promises.push(props.removeTag(props.course.slug, tag));
    });
    return promises;
  };

  const submitApprovalForm = () => {
    setSubmitting(true);

    // Get staff user objects from selected staff user options
    const programManager = props.wikiEdStaff.find(user => user.role === 'classroom_program_manager');
    const wikiExpert = props.wikiEdStaff.find(user => user.username === selectedWikiExpert.value);

    let promises = [];
    promises = promises.concat(submitWikiEdStaff(programManager, wikiExpert));
    promises = promises.concat(submitCampaigns());
    promises = promises.concat(submitTags());

    Promise.all(promises).finally(() => {
      setSubmitting(false);
    });
  };

  const programManager = props.wikiEdStaff.length > 0 ? setProgramManager() : null;
  const wikiExpertOptions = props.wikiEdStaff.length > 0 ? setWikiExpertOptions() : [];

  const campaignOptions = props.allCampaigns.map((campaign) => {
      return { value: campaign.title, label: campaign.title };
  });

  const allTagOptions = uniq(props.allTags).map((tag) => {
    return { label: tag, value: tag };
  });
  const tagOptions = [...createdTagOption, ...allTagOptions];


  const programManagerSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label htmlFor="program_manager">Add Program Manager</label>
      </div>
      <div className="group-right">
        <Select
          id={'program_manager'}
          value={programManager}
          onChange={null}
          options={[]}
          simpleValue
          styles={selectStyles}
        />
      </div>
    </div>
  );

  const wikiExpertSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label htmlFor="wiki_expert">Add Wikipedia Expert</label>
      </div>
      <div className="group-right">
        <Select
          id={'wiki_expert'}
          value={wikiExpertOptions.empty ? null : selectedWikiExpert}
          onChange={handleWikiExpertChange}
          options={wikiExpertOptions}
          simpleValue
          styles={selectStyles}
        />
      </div>
    </div>
  );

  const tagsSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label htmlFor="campaign">Add Tags</label>
      </div>
      <div className="group-right">
        <CreatableSelect
          id={'tags'}
          value={selectedTags}
          placeholder={I18n.t('courses.tag_select')}
          onChange={handleTagChange}
          options={tagOptions}
          styles={selectStyles}
          isMulti={true}
          isClearable={false}
        />
      </div>
    </div>
  );

  const campaignsSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label htmlFor="campaign">Add Campaigns</label>
      </div>
      <div className="group-right">
        <Select
          id={'campaign'}
          value={campaignOptions.empty ? null : selectedCampaigns}
          onChange={handleCampaignsChange}
          options={campaignOptions}
          simpleValue
          styles={selectStyles}
          isMulti={true}
          isClearable={false}
        />
      </div>
    </div>
  );

  const approveButton = (submitting) ? (
    <div className="course-approval-loader">
      <div>Submitting ... </div>
      <div className="loading__spinner__small" />
    </div>
    ) : (
      <div className="controls">
        <button className="dark button" onClick={submitApprovalForm}>Approve Course</button>
      </div>);

  return (
    <div className="module course-approval">
      <div className="section-header">
        <h3>Course Approval Form</h3>
        {approveButton}
      </div>
      <div className="course-approval-form">
        {programManagerSelector}
        {wikiExpertSelector}
        {tagsSelector}
        {campaignsSelector}
      </div>
    </div>
  );
};

CourseApproval.propTypes = {
  course: PropTypes.object,
  fetchSpecialUsers: PropTypes.func,
  fetchAllCampaigns: PropTypes.func,
  addUser: PropTypes.func,
  addCampaign: PropTypes.func,
  allCampaigns: PropTypes.array,
  wikiEdStaff: PropTypes.array,
  tags: PropTypes.array,
  allTags: PropTypes.array,
  fetchAllTags: PropTypes.func,
  addTag: PropTypes.func,
  removeTag: PropTypes.func
};

const mapStateToProps = state => ({
  course: state.course,
  wikiEdStaff: getCourseApprovalStaff(state),
  allCampaigns: state.campaigns.all_campaigns,
  tags: state.tags.tags,
  allTags: state.tags.allTags
});

const mapDispatchToProps = {
  fetchSpecialUsers,
  fetchAllCampaigns,
  fetchAllTags,
  addUser,
  addCampaign,
  addTag,
  removeTag,
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
