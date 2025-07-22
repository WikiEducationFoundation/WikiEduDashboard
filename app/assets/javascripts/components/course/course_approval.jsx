import React, { useEffect, useState } from 'react';

import { connect } from 'react-redux';
import { difference, uniq } from 'lodash-es';

import PropTypes from 'prop-types';
import Select from 'react-select';
import TextInput from '../common/text_input';
import CreatableSelect from 'react-select/creatable';
import selectStyles from '../../styles/single_select';

import { fetchSpecialUsers } from '../../actions/settings_actions';
import { fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { removeTag, fetchAllTags, addTag } from '../../actions/tag_actions';
import { linkToSalesforce } from '../../actions/course_actions';
import { addUser } from '../../actions/user_actions';
import { getCourseApprovalStaff } from '../../selectors';
import { STAFF_ROLE } from '../../constants';
import { inferDefaultCampaign } from './utils/inferDefaultCampaign';
import { extractSalesforceId } from '../../utils/salesforce_utils.js';


const CourseApproval = (props) => {
  const [selectedWikiExpert, setSelectedWikiExpert] = useState({});
  const [selectedCampaigns, setSelectedCampaigns] = useState([]);
  const [selectedTags, setSelectedTags] = useState([]);
  const [createdTagOption, setCreatedTagOption] = useState([]);
  const [salesforceId, setSalesforceId] = useState('');
  const [showInvalidIdMessage, setShowInvalidIdMessage] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    props.fetchSpecialUsers();
    props.fetchAllCampaigns();
    props.fetchAllTags();

    // Cleanup function to clear all states after component unmounts
    return function cleanUp() {
      setSelectedWikiExpert({});
      setSelectedCampaigns([]);
      setSelectedTags([]);
      setCreatedTagOption([]);
      setSubmitting(false);
    };
  }, []);

  useEffect(() => {
    if (props.wikiEdStaff.length > 0) {
      const wikiExpert = props.wikiEdStaff.find(user => user.role === 'wikipedia_expert');
      const currentWikiExpert = props.wikiEdStaff.find(user => user.role === 'wikipedia_expert' && user.already_selected);

      // Check if there exists a wiki expert who is already allotted a staff role. If yes, set that
      // user as selectedWikiExpert. Else, set the first wikipedia expert user as the selectedWikiExpert.
      setSelectedWikiExpert(
        (currentWikiExpert !== null && currentWikiExpert !== undefined)
          ? { value: currentWikiExpert.username, label: `${currentWikiExpert.username} (${currentWikiExpert.realname})` }
          : { value: wikiExpert.username, label: `${wikiExpert.username} (${wikiExpert.realname})` }
      );
    }

    if (props.allCampaigns.length > 0) {
      const defaultCampaign = inferDefaultCampaign(props.allCampaigns, props.course.start);
      if (defaultCampaign !== null) {
        setSelectedCampaigns([{ value: defaultCampaign.title, label: defaultCampaign.title }]);
      }
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

  const handleWikiExpertChange = (selectedOption) => {
    return setSelectedWikiExpert(selectedOption);
  };

  const handleCampaignsChange = (selectedOptions) => {
    return setSelectedCampaigns(selectedOptions);
  };

  const handleTagChange = (selectedOption) => {
    if (!selectedOption) {
      return setSelectedTags(null);
    }

    // The value includes `__isNew__: true` if it's a user-created option.
    // In that case, we need to add it to the list of options, so that it shows up as selected.
    const isNew = selectedOption.__isNew__;
    if (isNew) {
      setCreatedTagOption([selectedOption]);
    }
    setSelectedTags(selectedOption);
  };

  const handleSalesforceIdChange = (key, value) => {
    return setSalesforceId(value);
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

    const newTags = difference(currentTags, oldTags); // newly added tags
    const removedTags = difference(oldTags, currentTags); // tags removed by current selection

    const promises = [];
    newTags.forEach((tag) => {
      promises.push(props.addTag(props.course.slug, tag));
    });
    removedTags.forEach((tag) => {
      promises.push(props.removeTag(props.course.slug, tag));
    });
    return promises;
  };

  // Check if entered id is valid and return it if it is valid
  const validateSalesforceId = () => {
    const rawSalesforceId = salesforceId;
    if (!rawSalesforceId) {
      // Return true as empty text field is allowed
      // Return empty array required for concatenation
      return { isValid: true, promise: [] };
    }
    const _salesforceId = extractSalesforceId(rawSalesforceId);
    if (!_salesforceId) {
      // Return false if extracted id is invalid
      return { isValid: false, promise: null };
    }
    const promise = props.linkToSalesforce(props.course.id, _salesforceId);
    return { isValid: true, promise: [promise] };
  };

  const submitApprovalForm = () => {
    setSubmitting(true);

    // Get staff user objects from selected staff user options
    const programManager = props.wikiEdStaff.find(user => user.role === 'classroom_program_manager');
    const wikiExpert = props.wikiEdStaff.find(user => user.username === selectedWikiExpert.value);

    let promises = [];
    const idValidation = validateSalesforceId();
    if (!idValidation.isValid) {
      setSubmitting(false);
      setShowInvalidIdMessage(true);
      return;
    }
    promises = promises.concat(idValidation.promise);
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
        <label id="program_manager-label" htmlFor="program_manager">Add Program Manager:</label>
      </div>
      <div className="group-right">
        <Select
          id={'program_manager'}
          value={programManager}
          onChange={null}
          options={[]}
          simpleValue
          styles={selectStyles}
          aria-labelledby="program_manager-label"
        />
      </div>
    </div>
  );

  const wikiExpertSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label id="wiki_expert-label" htmlFor="wiki_expert">Add Wikipedia Expert:</label>
      </div>
      <div className="group-right">
        <Select
          id={'wiki_expert'}
          value={wikiExpertOptions.empty ? null : selectedWikiExpert}
          onChange={handleWikiExpertChange}
          options={wikiExpertOptions}
          simpleValue
          styles={selectStyles}
          aria-labelledby="wiki_expert-label"
        />
      </div>
    </div>
  );

  const tagsSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label id="tag-select-label" htmlFor="tags">Add Tags:</label>
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
          aria-labelledby="tag-select-label"
        />
      </div>
    </div>
  );

  const campaignsSelector = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label id="campaign-select-label" htmlFor="campaign">Add Campaigns: <span className="form-required-indicator">*</span></label>
      </div>
      <div className="group-right">
        <Select
          id={'campaign'}
          value={campaignOptions.empty ? null : selectedCampaigns}
          placeholder={I18n.t('courses.campaign_select')}
          onChange={handleCampaignsChange}
          options={campaignOptions}
          simpleValue
          styles={selectStyles}
          isMulti={true}
          isClearable={false}
          aria-labelledby="campaign-select-label"
        />
      </div>
    </div>
  );

  let invalidIdMessage;
  if (showInvalidIdMessage) {
    invalidIdMessage = <p className="form-group invalid">The entered Id is not valid.</p>;
  }

  const salesforceIdField = (
    <div className="course-approval-field form-group">
      <div className="group-left form-group">
        <label id="salesforce-id-label" htmlFor="salesforce-id">Add Salesforce Id: </label>
      </div>
      <div className="group-right">
        <TextInput
          id="salesforce-id"
          onChange={handleSalesforceIdChange}
          value={salesforceId}
          value_key="salesforceId"
          editable={true}
          type="text"
          aria-labelledby="salesforce-id-label"
        />
        {invalidIdMessage}
      </div>
    </div>
  );

  const approveButtonState = (selectedCampaigns === null || selectedCampaigns.length === 0) ? 'disabled' : '';
  const approveButton = (submitting) ? (
    <div className="course-approval-loader">
      <div>Approving ... </div>
      <div className="loading__spinner__small" />
    </div>
    ) : (
      <div className="controls">
        <button className={`dark button ${approveButtonState}`} onClick={submitApprovalForm}>Approve Course</button>
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
        {salesforceIdField}
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
  removeTag: PropTypes.func,
  linkToSalesforce: PropTypes.func
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
  linkToSalesforce
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
