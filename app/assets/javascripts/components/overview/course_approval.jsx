import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';
import { fetchSpecialUsers } from '../../actions/settings_actions';
import { fetchAllCampaigns, addCampaign } from '../../actions/campaign_actions';
import { addUser } from '../../actions/user_actions';
import { getStaffUsers } from '../../selectors';

const CourseApproval = createReactClass({
    displayName: 'CourseApproval',

    propTypes: {
      fetchSpecialUsers: PropTypes.func,
      fetchAllCampaigns: PropTypes.func,
      addUser: PropTypes.func,
      addCampaign: PropTypes.func,
      specialUsers: PropTypes.object,
      allCampaigns: PropTypes.array,
      wikiEdStaff: PropTypes.array
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
      if (this.props.specialUsers !== prevProps.specialUsers) {
        if (this.props.specialUsers.classroom_program_manager) {
          const username = this.props.specialUsers.classroom_program_manager[0].username;
          const realname = this.props.specialUsers.classroom_program_manager[0].real_name;
          this.setState({
            programManager: {
              value: `${username}-${realname}`,
              label: `${username} (${realname})`,
            }
          }, this.setWikiExpertUser);
        }

        if (this.props.specialUsers.wikipedia_experts) {
          this.setState({
            wikiExpertOptions: this.props.specialUsers.wikipedia_experts.map((user) => {
              const username = user.username;
              const realname = user.real_name;
              return { value: `${username}-${realname}`, label: `${username} (${realname})` };
            })
          });
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

    setWikiExpertUser() {
        const programManager = this.state.programManager;
        const user = this.props.wikiEdStaff.filter(user => user.username !== programManager.value.split("-")[0]);
        if (user.length>0) {
          const username = user[0].username;
          const realname = user[0].real_name;
          this.setState({
            selectedWikiExpert: { value: `${username}-${realname}`, label: `${username} (${realname})`}
          });
        }
        else {
          if (this.state.wikiExpertOptions.length>0) {
            this.setState({
              selectedWikiExpert: {
                value: this.state.wikiExpertOptions[0].value,
                label: this.state.wikiExpertOptions[0].label,
              }
            });
          }
        }
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
                onChange={this._handleProgramManagerChange}
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
  specialUsers: state.settings.specialUsers,
  allCampaigns: state.campaigns.all_campaigns,
  wikiEdStaff: getStaffUsers(state)
});

const mapDispatchToProps = {
  fetchSpecialUsers,
  fetchAllCampaigns,
  addUser,
  addCampaign
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
