import React from 'react';

import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';
import { fetchSpecialUsers } from '../../actions/settings_actions';


const CourseApproval = createReactClass({
    displayName: 'CourseApproval',

    propTypes: {
      fetchSpecialUsers: PropTypes.func,
      specialUsers: PropTypes.object,
    },

    getInitialState() {
      return {
        selectedProgramManager: {},
        selectedWikiExpert: {},
        selectedCampaign: {},
        programManagerOptions: [],
        wikiExpertOptions: [],
        campaignOptions: []
      };
    },

    componentDidMount() {
      this.props.fetchSpecialUsers();
    },

    componentDidUpdate(prevProps) {
      if (this.props.specialUsers !== prevProps.specialUsers ) {
        if (this.props.specialUsers.classroom_program_manager) {
          this.setState({
            selectedProgramManager: {
              value: this.props.specialUsers.classroom_program_manager[0].username,
              label: this.props.specialUsers.classroom_program_manager[0].username,
            },
            programManagerOptions: this.props.specialUsers.classroom_program_manager.map((user) => {
              return { value: user.username, label: user.username };
            })
          });
        }

        if (this.props.specialUsers.wikipedia_experts) {
          this.setState({
            selectedWikiExpert: {
              value: this.props.specialUsers.wikipedia_experts[0].username,
              label: this.props.specialUsers.wikipedia_experts[0].username,
            },
            wikiExpertOptions: this.props.specialUsers.wikipedia_experts.map((user) => {
              return { value: user.username, label: user.username };
            })
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

    render() {
        const { programManagerOptions, wikiExpertOptions, campaignOptions, 
        selectedProgramManager, selectedWikiExpert, selectedCampaign } = this.state;
        
        const programManagerValue = programManagerOptions.empty ? null : programManagerOptions.find(option => option.value === selectedProgramManager.value);
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
                value={programManagerValue}
                onChange={this._handleProgramManagerChange}
                options={programManagerOptions}
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
});

const mapDispatchToProps = {
  fetchSpecialUsers,
};

export default connect(mapStateToProps, mapDispatchToProps)(CourseApproval);
