import React from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import { initiateConfirm } from '../../actions/confirm_actions';
import Popover from '../common/popover.jsx';
import useExpandablePopover from '../../hooks/useExpandablePopover';
import CategoriesScoping from '../course_creator/scoping_methods/categories_scoping';
import PagePileScoping from '../course_creator/scoping_methods/pagepile_scoping';
import PetScanScoping from '../course_creator/scoping_methods/petscan_scoping';
import TemplatesScoping from '../course_creator/scoping_methods/templates_scoping';
import { getAddCategoriesPayload } from '../util/scoping_methods';
import { resetScopingMethod } from '../../actions/scoping_methods';

const AddCategoryButton = ({
  course,
  source,
  addCategory,
}) => {
  const scopingMethods = useSelector(state => state.scopingMethods);
  const dispatch = useDispatch();

  const getKey = () => `add_${source}_button`;
  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const addCategoryHandler = (e) => {
    e.preventDefault();
    const payload = {
      ...getAddCategoriesPayload({
        sourceType: source,
        scopingMethods,
      }),
      course_id: course.id,
      source,
    };
    const onConfirm = () => {
      addCategory(payload);
      dispatch(resetScopingMethod());
      open(null);
    };
    const confirmMessage = I18n.t('categories.confirm_add_n_scoping_method', { n: payload.categories.items.length });
    dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  };

  let description;

  if (source === 'pileid') {
    description = (
      <p>
        {I18n.t('categories.pileid_description')}
      </p>
    );
  } else if (source === 'psid') {
    description = (
      <p>
        {I18n.t('categories.psid_description')}
      </p>
    );
  }

  const permitted = true;
  let className = 'button border small assign-button';
  if (isOpen) { className += ' dark'; }

  const buttonText = I18n.t(`categories.add_${source}`);
  const showButton = <button className={`${className}`} onClick={open}>{buttonText}</button>;

  let editRow = null;
  if (permitted) {
    let inputField;
    if (source === 'category') {
      inputField = <CategoriesScoping vertical />;
    } else if (source === 'psid') {
      inputField = <PetScanScoping />;
    } else if (source === 'pileid') {
      inputField = <PagePileScoping />;
    } else {
      inputField = <TemplatesScoping />;
    }
    editRow = (
      <tr className="edit">
        <td>
          <form
            onSubmit={addCategoryHandler}
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '1em',
            }}
            className="category-add-form"
          >
            {description}
            {inputField}
            <button className="button border" type="submit">
              {I18n.t(`categories.add_this_${source}`)}
            </button>
          </form>
        </td>
      </tr>
    );
  }

  return (
    <div className="pop__container" ref={ref}>
      {showButton}
      <Popover
        is_open={isOpen}
        edit_row={editRow}
        styles={{
          width: '500px',
        }}
      />
    </div>
  );
};

AddCategoryButton.propTypes = {
  course: PropTypes.object.isRequired,
  source: PropTypes.string.isRequired,
  addCategory: PropTypes.func,
};

export default AddCategoryButton;
