import React from 'react';
import WikiSelect from '../common/wiki_select.jsx';
import selectStyles from '../../styles/select';

// Wrapper component for WikiSelect. This allows you to click the "Change"
// link in order to change the selected wiki.
export default class SelectedWikiOption extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show: false
    };
  }

  handleShowOptions(e) {
    e.preventDefault();
    return this.setState(prevState => ({ show: !prevState.show }));
  }

  render() {
    const { language, project } = this.props;
    if (this.state.show) {
      return (
        <div className="wiki-select">
          <WikiSelect
            wikis={[{ language, project }]}
            onChange={this.props.handleWikiChange}
            multi={false}
            styles={{ ...selectStyles, singleValue: null }}
          />
          <div className="small-block-link">
            {language}.{project}.org <a href="#" onClick={this.handleShowOptions.bind(this)}>({I18n.t('articles.hide')})</a>
          </div>
        </div>
      );
    }

    return (
      <div className="small-block-link">
        {language}.{project}.org <a href="#" onClick={this.handleShowOptions.bind(this)}>({I18n.t('application.change')})</a>
      </div>
    );
  }
}
