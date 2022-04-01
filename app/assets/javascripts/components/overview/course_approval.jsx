import React from 'react';
import createReactClass from 'create-react-class';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const CourseApproval = createReactClass({
    displayName: 'CourseApproval',

    getInitialState() {
      return {
        selectedProgramManager: { value: 'user2', label: 'User2' },
        selectedWikiExpert: { value: 'user2', label: 'User2' },
        selectedCampaign: { value: 'campaign1', label: 'Campaign1' }
      };
    },

    _handleProgramManagerChange(selectedOption) {
      return this.setState({ selectedProgramManager : selectedOption });
    },

    _handleWikiExpertChange(selectedOption) {
      return this.setState({ selectedWikiExpert : selectedOption });
    },

    _handleCampaignChange(selectedOption) {
      return this.setState({ selectedCampaign : selectedOption });
    },

    render() {
        const programManagerOptions = [
          { value: 'user1', label: 'User1' },
          { value: 'user2', label: 'User2' },
          { value: 'user3', label: 'User3' },
        ];

        const wikiExpertOptions = [
          { value: 'user1', label: 'User1' },
          { value: 'user2', label: 'User2' },
          { value: 'user3', label: 'User3' },
        ];

        const campaignOptions = [
          { value: 'campaign1', label: 'Campaign1' },
          { value: 'campaign2', label: 'Campaign2' },
          { value: 'campaign3', label: 'Campaign3' },
        ];

        const programManagerSelector = (
          <div className="course-approval-field form-group">
            <div className='group-left'>
              <label htmlFor="program_manager">Add Program Manager:</label>
            </div>
            <div className='group-right'> 
              <Select
                id={'program_manager'}
                value={programManagerOptions.find(option => option.value === this.state.selectedProgramManager.value)}
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
            <div className='group-left'>
              <label htmlFor="wiki_expert">Add Wiki Expert:</label>
            </div>
            <div className='group-right'> 
              <Select
                id={'wiki_expert'}
                value={wikiExpertOptions.find(option => option.value === this.state.selectedWikiExpert.value)}
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
            <div className='group-left'>
              <label htmlFor="campaign">Add Campaign:</label>
            </div>
            <div className='group-right'> 
              <Select
                id={'campaign'}
                value={campaignOptions.find(option => option.value === this.state.selectedCampaign.value)}
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
            <div className='course-approval-fields'>
              {programManagerSelector}
              {wikiExpertSelector}
              {campaignSelector}
            </div>
          </div>
        );
    }
});

export default CourseApproval;