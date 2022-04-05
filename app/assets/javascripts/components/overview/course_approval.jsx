import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';
import { fetchSpecialUsers } from '../../actions/settings_actions';
import { fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { addUser } from '../../actions/user_actions';
import { getCourseApprovalStaff } from '../../selectors';

const CourseApproval = createReactClass({
    displayName: 'CourseApproval',

    propTypes: {
      fetchSpecialUsers: PropTypes.func,
      fetchAllCampaigns: PropTypes.func,
      addUser: PropTypes.func,
      addCampaign: PropTypes.func,
      allCampaigns: PropTypes.array,
      wikiEdStaff: PropTypes.array,
    },

    getInitialState() {
      return {
        programManager: {},
        selectedWikiExpert: {},
        selectedCampaign: {},
        wikiExpertOptions: [],
        campaignOptions: []
      };
    },

    componentDidMount() {
      this.props.fetchSpecialUsers();
      this.props.fetchAllCampaigns();
    },

    componentDidUpdate(prevProps) {
      if (this.props.wikiEdStaff !== prevProps.wikiEdStaff) {
        if (this.props.wikiEdStaff.length>0) {
          var program_manager = this.props.wikiEdStaff.find((user) => user.role==="classroom_program_manager");
          this.setState({
            programManager: {
              value: program_manager.username,
              label: `${program_manager.username} (${program_manager.realname})`
            }
          });
          this.setWikiExpertUsers();
        }
      }
      if (this.props.allCampaigns !== prevProps.allCampaigns) {
        this.setState({
          selectedCampaign: {
            value: this.props.allCampaigns[0],
            label: this.props.allCampaigns[0],
          },
          campaignOptions: this.props.allCampaigns.map((campaign) => {
            return { value: campaign, label: campaign };
          })
        });
      }
    },

    setWikiExpertUsers() {
        const staff = this.props.wikiEdStaff;
        staff.forEach((user) => {
          if (user.role==="wikipedia_expert") {
            this.setState(prevState => ({
              wikiExpertOptions: [ ...prevState.wikiExpertOptions, {
                value: user.username,
                label: `${user.username} (${user.realname})`
              }]
            }));
          }
          if (user.already_selected) {
            this.setState({
              selectedWikiExpert: {
                value: user.username,
                label: `${user.username} (${user.realname})`
              }
            })
          }
        });
    },

    _handleProgramManagerChange(selectedOption) {
      return this.setState({ selectedProgramManager: selectedOption });
    },

    _handleWikiExpertChange(selectedOption) {
      return this.setState({ selectedWikiExpert: selectedOption });
    },

    _handleCampaignChange(selectedOption) {
      return this.setState({ selectedCampaign: selectedOption });
    },

    submitWikiEdStaff(programManager, wikiExpert) {
      const { course_id } = this.props;
      const programManagerUserObject = {
        username: programManager.value.split("-")[0],
        role: 4, 
        role_description: null,
        real_name: programManager.value.split("-")[1]
      };
      const wikiExpertUserObject = {
        username: wikiExpert.value.split("-")[0],
        role: 4, 
        role_description: null,
        real_name: wikiExpert.value.split("-")[1]
      };
      const addUserAction = this.props.addUser;
      addUserAction(course_id, { user: programManagerUserObject });
      addUserAction(course_id, { user: wikiExpertUserObject });
    },

    submitCampaign(campaign) {
      const { course_id } = this.props;
      this.props.addCampaign(course_id, campaign.value);
    },

    submitApprovalForm() {
      this.submitWikiEdStaff(this.state.programManager, this.state.selectedWikiExpert);
      this.submitCampaign(this.state.selectedCampaign);
    },

    render() {
        const { wikiExpertOptions, campaignOptions, 
        programManager, selectedWikiExpert, selectedCampaign } = this.state;
        
        const wikiExpertValue = wikiExpertOptions.empty ? null : wikiExpertOptions.find(option => option.value === selectedWikiExpert.value);
        const campaignValue = campaignOptions.empty ? null : campaignOptions.find(option => option.value === selectedCampaign.value);

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

        const campaignSelector = (
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
              />
            </div>
          </div>
        );

        return (
          <div className="module reviewer-section">
            <div className="section-header">
              <h3>Course Approval Form</h3>
              <div className='controls'>
                <button className='dark button' onClick={this.submitApprovalForm}>Approve Course</button>
              </div>
            </div>
            <div className="course-approval-fields">
              {programManagerSelector}
              {wikiExpertSelector}
              {campaignSelector}
            </div>
          </div>
        );
    }
});

const mapStateToProps = state => ({
  allCampaigns: state.campaigns.all_campaigns,
  wikiEdStaff: getCourseApprovalStaff(state)
});

const mapDispatchToProps = {
  fetchSpecialUsers,
  fetchAllCampaigns,
  addUser,
  addCampaign
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
