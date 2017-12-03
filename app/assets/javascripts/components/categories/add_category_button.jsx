import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextInput from '../common/text_input';

const AddCategoryButton = createReactClass({
  displayName: 'AddCategoryButton',

  render() {
    return (
      <tr className="edit">
        <td>
          <form onSubmit={this.addCategory}>
            <TextInput
              value="Ohai"
            />
            <button className="button border" type="submit">{I18n.t('categories.add_category')}</button>
          </form>
        </td>
      </tr>
    );
  }
}
);

export default AddCategoryButton;
