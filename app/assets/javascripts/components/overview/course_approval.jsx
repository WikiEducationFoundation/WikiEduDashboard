import React from 'react';

import { connect } from 'react-redux';
import { difference } from 'lodash-es';

import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';
import selectStyles from '../../styles/single_select';

import { fetchSpecialUsers } from '../../actions/settings_actions';
import { fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { removeTag, fetchAllTags, addTag } from '../../actions/tag_actions';
import { addUser } from '../../actions/user_actions';
import { getCourseApprovalStaff, getAvailableTags } from '../../selectors';
import { STAFF_ROLE } from '../../constants';


const CourseApproval = createReactClass({
    displayName: 'CourseApproval',

    propTypes: {
      fetchSpecialUsers: PropTypes.func,
      fetchAllCampaigns: PropTypes.func,
      addUser: PropTypes.func,
      addCampaign: PropTypes.func,
      allCampaigns: PropTypes.array,
      wikiEdStaff: PropTypes.array,
      tags: PropTypes.array,
      availableTags: PropTypes.array,
      fetchAllTags: PropTypes.func,
      addTag: PropTypes.func,
      removeTag: PropTypes.func
    },

    getInitialState() {
      return {
        programManager: {},
        selectedWikiExpert: {},
        selectedCampaigns: [],
        wikiExpertOptions: [],
        campaignOptions: [],
        createdTagOption: [],
        selectedTags: this.props.tags.map((tag) => {
          return { value: tag.tag, label: tag.tag };
        }),
      };
    },

    componentDidMount() {
      this.props.fetchSpecialUsers();
      this.props.fetchAllCampaigns();
      this.props.fetchAllTags();
    },

    componentDidUpdate(prevProps) {
      if (this.props.wikiEdStaff !== prevProps.wikiEdStaff) {
        if (this.props.wikiEdStaff.length > 0) {
          // Set state for classroom program manager and a default selected wiki expert
          const programManager = this.props.wikiEdStaff.find(user => user.role === 'classroom_program_manager');
          const wikiExpert = this.props.wikiEdStaff.find(user => user.role === 'wikipedia_expert');
          // eslint-disable-next-line react/no-did-update-set-state
          this.setState({
            programManager: {
              value: programManager.username,
              label: `${programManager.username} (${programManager.realname})`
            },
            selectedWikiExpert: {
              value: wikiExpert.username,
              label: `${wikiExpert.username} (${wikiExpert.realname})`
            }
          });
          this.setWikiExpertUsers();
        }
      }
      if (this.props.allCampaigns !== prevProps.allCampaigns) {
        // Set the first campaign as default selected campaign and add all the
        // campaigns to campaignOptions
        // eslint-disable-next-line react/no-did-update-set-state
        this.setState({
          selectedCampaigns: [{
            value: this.props.allCampaigns[0],
            label: this.props.allCampaigns[0],
          }],
          campaignOptions: this.props.allCampaigns.map((campaign) => {
            return { value: campaign, label: campaign };
          })
        });
      }
    },

    setWikiExpertUsers() {
        const staff = this.props.wikiEdStaff;

        // Set state for wikiExpertOptions and if any wikipedia expert was already
        // assigned a staff user role for this course, make them selectedWikiExpert
        staff.forEach((user) => {
          if (user.role === 'wikipedia_expert') {
            this.setState(prevState => ({
              wikiExpertOptions: [...prevState.wikiExpertOptions, {
                value: user.username,
                label: `${user.username} (${user.realname})`
              }]
            }));
            if (user.already_selected) {
              this.setState({
                selectedWikiExpert: {
                  value: user.username,
                  label: `${user.username} (${user.realname})`
                }
              });
            }
          }
        });
    },

    _handleWikiExpertChange(selectedOption) {
      return this.setState({ selectedWikiExpert: selectedOption });
    },

    _handleCampaignChange(selectedOptions) {
      return this.setState({ selectedCampaigns: selectedOptions });
    },

    handleTagsChange(val) {
      if (!val) {
        return this.setState({ selectedTag: null });
      }
  
      // The value includes `__isNew__: true` if it's a user-created option.
      // In that case, we need to add it to the list of options, so that it shows up as selected.
      const isNew = val.__isNew__;
      if (isNew) {
        this.setState({ createdTagOption: [val] });
      }
      this.setState({ selectedTags: val });
    },

    submitWikiEdStaff(programManager, wikiExpert) {
      const { course_id } = this.props;
      const addUserAction = this.props.addUser;

      // Only add the program manager, if they are not already assigned a staff role
      if (!programManager.already_selected) {
        const programManagerUserObject = {
          username: programManager.username,
          role: STAFF_ROLE,
          role_description: null,
          real_name: programManager.realname
        };
        addUserAction(course_id, { user: programManagerUserObject });
      }

      // Only add the selected wiki expert, if they are not already assigned a staff role
      if (!wikiExpert.already_selected) {
        const wikiExpertUserObject = {
          username: wikiExpert.username,
          role: STAFF_ROLE,
          role_description: null,
          real_name: wikiExpert.realname
        };
        addUserAction(course_id, { user: wikiExpertUserObject });
      }
    },

    submitCampaign(campaigns) {
      const { course_id } = this.props;
      if (campaigns.length > 0) {
        campaigns.forEach((campaign) => {
          this.props.addCampaign(course_id, campaign.value);
        });
      }
    },

    submitTags() {
      const currentTags = this.props.tags.map(tag => tag.tag);
      const selectedTags = this.state.selectedTags.map(tag => tag.value);

      const newTags = difference(selectedTags, currentTags);
      const removedTags = difference(currentTags, selectedTags);
      const { course_id } = this.props;

      newTags.forEach((tag) => {
        this.props.addTag(course_id, tag);
      });
      removedTags.forEach((tag) => {
        this.props.removeTag(course_id, tag);
      });
    },

    submitApprovalForm() {
      // Get staff user objects from selected staff user options
      const programManager = this.props.wikiEdStaff.find(user => user.username === this.state.programManager.value);
      const wikiExpert = this.props.wikiEdStaff.find(user => user.username === this.state.selectedWikiExpert.value);

      this.submitWikiEdStaff(programManager, wikiExpert);
      this.submitCampaign(this.state.selectedCampaigns);
      this.submitTags();
    },

    render() {
        const { wikiExpertOptions, campaignOptions,
        programManager, selectedWikiExpert, selectedCampaigns } = this.state;

        const wikiExpertValue = wikiExpertOptions.empty ? null : selectedWikiExpert;
        const campaignValue = campaignOptions.empty ? null : selectedCampaigns;

        const availableTagOptions = this.props.availableTags.map((tag) => {
          return { label: tag, value: tag };
        });
        const tagOptions = [...this.state.createdTagOption, ...availableTagOptions];

        const programManagerSelector = (
          <div className="course-approval-field form-group">
            <div className="group-left">
              <label htmlFor="program_manager">Add Program Manager:</label>
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
            <div className="group-left">
              <label htmlFor="wiki_expert">Add Wiki Expert:</label>
            </div>
            <div className="group-right">
              <Select
                id={'wiki_expert'}
                value={wikiExpertValue}
                onChange={this._handleWikiExpertChange}
                options={wikiExpertOptions}
                simpleValue
                styles={selectStyles}
              />
            </div>
          </div>
        );

        const campaignsSelector = (
          <div className="course-approval-field form-group">
            <div className="group-left">
              <label htmlFor="campaign">Add Campaign:</label>
            </div>
            <div className="group-right">
              <Select
                id={'campaign'}
                value={campaignValue}
                onChange={this._handleCampaignChange}
                options={campaignOptions}
                simpleValue
                styles={selectStyles}
                isMulti={true}
                isClearable={false}
              />
            </div>
          </div>
        );

        const tagsSelector = (
          <div className="course-approval-field form-group">
            <div className="group-left">
              <label htmlFor="campaign">Add tags:</label>
            </div>
            <div className="group-right select-with-button">
              <CreatableSelect
                className="fixed-width"
                ref="tagSelect"
                name="tag"
                value={this.state.selectedTags}
                placeholder={I18n.t('courses.tag_select')}
                onChange={this.handleTagsChange}
                options={tagOptions}
                styles={selectStyles}
                isMulti={true}
                isClearable={false}
              />
            </div>
          </div>
        );

        return (
          <div className="module reviewer-section">
            <div className="section-header">
              <h3>Course Approval Form</h3>
              <div className="controls">
                <button className="dark button" onClick={this.submitApprovalForm}>Approve Course</button>
              </div>
            </div>
            <div className="course-approval-fields">
              {programManagerSelector}
              {wikiExpertSelector}
              {campaignsSelector}
              {tagsSelector}
            </div>
          </div>
        );
    }
});

const mapStateToProps = state => ({
  allCampaigns: state.campaigns.all_campaigns,
  wikiEdStaff: getCourseApprovalStaff(state),
  availableTags: getAvailableTags(state),
  tags: state.tags.tags
});

const mapDispatchToProps = {
  fetchSpecialUsers,
  fetchAllCampaigns,
  addUser,
  addCampaign,
  removeTag,
  addTag,
  fetchAllTags
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
