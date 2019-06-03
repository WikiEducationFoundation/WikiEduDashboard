import React from 'react';
import CreatableSelect from 'react-select/lib/Creatable';
import selectStyles from '../../styles/select';

class CreatableInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selected: null
    };

    this.onModify = this.onModify.bind(this);
  }

  onModify({ value }) {
    if (value) {
      this.setState({ selected: { label: value, value } });
      this.props.onChange({ value });
    }
  }

  render() {
    const { label, id, options, placeholder } = this.props;

    return (
      <div>
        <span className="text-input-component__label">
          <strong>{label}</strong>
        </span>
        <CreatableSelect
          id={id}
          onChange={this.onModify}
          onBlur={element => this.onModify({ value: element.target.value })}
          options={options}
          placeholder={placeholder}
          value={this.state.selected}
          styles={{ ...selectStyles, singleValue: null }}
        />
      </div>
    );
  }
}

export default CreatableInput;
