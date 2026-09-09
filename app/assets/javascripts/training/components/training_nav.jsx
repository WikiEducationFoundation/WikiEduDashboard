import React,{ useEffect } from 'react';
import TrainingHamburger from "./training_hamburger.jsx";
import BreadCrumbs from "./bread_crumbs.jsx";
import GetHelpButton from '../../components/common/get_help_button.jsx';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { fetchCourse} from '../../actions/course_actions';
import { fetchUsers } from '../../actions/user_actions.js';
import {getCurrentUser} from '../../selectors';

const TrainingNav = (props)=>{
  useEffect(() => {
    const courseSlug = getCourseSlug();
    if (courseSlug){
      props.fetchCourse(courseSlug);
      props.fetchUsers(courseSlug);
    }
  }, []);
  const getCourseSlug = () => {
    const courseSlug = document.getElementById("react_root").getAttribute("data-course-slug");
    if (courseSlug){
       return courseSlug;
    }
  };
  const usersignedin = document.getElementById("react_root").getAttribute("data-usersignedin")  === "true";
 return (
    <header className="training__slide-header">
      <div className="training__nav-container">
        <div className="training__breadcrumbs nav__item">
          <BreadCrumbs/>
        </div>
        <div className="training__actions nav__item">
          {usersignedin && (

                      <div className="nav__button" id="get-help-button">

                        <GetHelpButton course={props.course} currentUser={props.currentUser} key="get_help"/></div>)}
          <div className="hamburger-wrapper ">
            <TrainingHamburger/>
          </div>
        </div>
      </div>
  </header>
)
};

TrainingNav.propTypes = {
  course: PropTypes.object
};

const mapStateToProps = state => ({
  course: state.course,
  currentUser: getCurrentUser(state)
});

const mapDispatchToProps = {
  fetchCourse,
  fetchUsers,
};

export default connect(mapStateToProps,mapDispatchToProps)(TrainingNav);