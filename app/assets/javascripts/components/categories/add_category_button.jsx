import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import React from 'react';
import { initiateConfirm } from '../../actions/confirm_actions';
import Popover from '../common/popover.jsx';
import Expandable from '../high_order/expandable.jsx';

import CategoriesScoping from '../course_creator/scoping_methods/categories_scoping';
import PagePileScoping from '../course_creator/scoping_methods/pagepile_scoping';
import PetScanScoping from '../course_creator/scoping_methods/petscan_scoping';
import TemplatesScoping from '../course_creator/scoping_methods/templates_scoping';
import { getAddCategoriesPayload } from '../util/scoping_methods';
import { resetScopingMethod } from '../../actions/scoping_methods';

const AddCategoryButton = createReactClass({
  displayName: 'AddCategoryButton',

  propTypes: {
    course: PropTypes.object.isRequired,
    is_open: PropTypes.bool,
    open: PropTypes.func.isRequired,
    initiateConfirm: PropTypes.func,
    addCategory: PropTypes.func,
    source: PropTypes.string.isRequired
  },

  getKey() {
    return `add_${this.props.source}_button`;
  },

  addCategory(e) {
    e.preventDefault();
    const addCategory = this.props.addCategory;
    const payload = {
      ...getAddCategoriesPayload({
        sourceType: this.props.source,
        scopingMethods: this.props.scopingMethods,
      }),
      course_id: this.props.course.id,
      source: this.props.source,
    };
    const resetScoping = this.props.resetScopingMethod;
    const open = this.props.open;
    const onConfirm = function () {
      addCategory(payload);
      resetScoping();
      open(null);
    };

    const confirmMessage = 'Are you sure you want to track these categories?';
    return this.props.initiateConfirm({ confirmMessage, onConfirm });
  },


  render() {
    let description;
      if (this.props.source === 'pileid') {
        description = (
          <p>
            Make sure the PagePile&apos;s wiki is one of the tracked wikis for this program.
          </p>
        );
      } else if (this.props.source === 'psid') {
        description = (
          <p>
            PetScan queries only work with the Dashboard one wiki at a time. Ensure that your PetScan query includes only articles from a single wiki, and that it matches the wiki set below.
          </p>
        );
      }
    const permitted = true;
    let className = 'button border small assign-button';
    if (this.props.is_open) { className += ' dark'; }

    const buttonText = I18n.t(`categories.add_${this.props.source}`);
    const showButton = <button className={`${className}`} onClick={this.props.open}>{buttonText}</button>;

    let editRow;
    if (permitted) {
      let inputField;
      if (this.props.source === 'category') {
        inputField = <CategoriesScoping vertical/>;
      } else if (this.props.source === 'psid') {
        inputField = <PetScanScoping/>;
      } else if (this.props.source === 'pileid') {
        inputField = <PagePileScoping />;
      } else {
        inputField = <TemplatesScoping />;
      }
      editRow = (
        <tr className="edit">
          <td>
            <form
              onSubmit={this.addCategory} style={{
              display: 'flex',
              flexDirection: 'column',
            }}
              className="category-add-form"
            >
              {description}
              {inputField}
              <p style={{
                textAlign: 'end',
                fontSize: '12px',
                fontWeight: 'lighter'
              }}
              >Note: Changing the wiki will only affect the items that are added after the change.
              </p>
              <button className="button border" type="submit">
                {I18n.t(`categories.add_this_${this.props.source}`)}
              </button>
            </form>
          </td>
        </tr>
      );
    }

    return (
      <div className="pop__container">
        {showButton}
        <Popover
          is_open={this.props.is_open}
          edit_row={editRow}
          styles={{
            width: '500px'
          }}
        />
      </div>
    );
  }
});

const mapDispatchToProps = { initiateConfirm, resetScopingMethod };
const mapStateToProps = state => ({
  scopingMethods: state.scopingMethods,
});
export default connect(mapStateToProps, mapDispatchToProps)(
  Expandable(AddCategoryButton)
);
