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
    },

    getInitialState() {
      return {
        programManager: {},
        selectedWikiExpert: {},
        selectedCampaigns: [],
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
          selectedCampaigns: {
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

    submitApprovalForm() {
      // Get staff user objects from selected staff user options
      const programManager = this.props.wikiEdStaff.find(user => user.username === this.state.programManager.value);
      const wikiExpert = this.props.wikiEdStaff.find(user => user.username === this.state.selectedWikiExpert.value);

      this.submitWikiEdStaff(programManager, wikiExpert);
      this.submitCampaign(this.state.selectedCampaigns);
    },

    render() {
        const { wikiExpertOptions, campaignOptions,
        programManager, selectedWikiExpert, selectedCampaigns } = this.state;

        const wikiExpertValue = wikiExpertOptions.empty ? null : selectedWikiExpert;
        const campaignValue = campaignOptions.empty ? null : selectedCampaigns;

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
                isMulti={true}
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
