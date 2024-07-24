import React, { useState, useEffect, useCallback } from "react";
import PropTypes from "prop-types";
import Modal from "../common/modal.jsx";
import TextInput from "../common/text_input.jsx";
import DatePicker from "../common/date_picker.jsx";
import TextAreaInput from "../common/text_area_input.jsx";
import Calendar from "../common/calendar.jsx";
import CourseUtils from "../../utils/course_utils.js";
import CourseDateUtils from "../../utils/course_date_utils.js";

const CourseClonedModal = ({
  course,
  initiateConfirm,
  deleteCourse,
  updateCourse,
  updateClonedCourse,
  currentUser,
  setValid,
  setInvalid,
  isValid,
  activateValidations,
  firstErrorMessage,
  courseCreationNotice,
}) => {
  const [state, setState] = useState({
    course: course,
    tempCourseId: CourseUtils.generateTempId(course),
    isPersisting: false,
    anyDatesSelected: false,
    blackoutDatesSelected: false,
    valuesUpdated: false,
  });

  const addValidation = useCallback(
    (field, message) => {
      activateValidations();
      console.log(`Validation added for ${field}: ${message}`);
    },
    [activateValidations]
  );

  useEffect(() => {
    if (course.type !== "ClassroomProgramCourse") return;
    addValidation("weekdays", "Set the meeting days.");
    addValidation(
      "holidays",
      'Mark the holidays, or check "I have no class holidays".'
    );
  }, [course.type, addValidation]);

  useEffect(() => {
    if (firstErrorMessage) {
      try {
        document
          .querySelector(".wizard")
          .scrollTo({ top: 0, behavior: "smooth" });
      } catch (_err) {
        console.log("scroll error", _err);
      }
    }
  }, [firstErrorMessage]);

  const setAnyDatesSelected = (bool) => {
    setState((prevState) => ({
      ...prevState,
      anyDatesSelected: bool,
    }));
  };

  const setBlackoutDatesSelected = (bool) => {
    setState((prevState) => ({
      ...prevState,
      blackoutDatesSelected: bool,
    }));
  };

  const setNoBlackoutDatesChecked = () => {
    const checked = document.getElementById("noDates").checked;
    if (checked) setValid("holidays");
    handleChange(checked, "no_day_exceptions");
  };

  const cancelCloneCourse = () => {
    const i18nPrefix = course.string_prefix;
    const confirmMessage = CourseUtils.i18n(
      "creator.cancel_course_clone_confirm",
      i18nPrefix
    );
    const onConfirm = () => {
      deleteCourse(state.course.slug);
    };
    initiateConfirm({ confirmMessage, onConfirm });
  };

  const updateCourseField = (valueKey, value) => {
    const updatedCourse = { ...state.course, [valueKey]: value };
    setState((prevState) => ({
      ...prevState,
      valuesUpdated: true,
      course: updatedCourse,
    }));

    if (valueKey === "term") {
      setValid("exists");
    }
    if (updatedCourse.term && ["title", " ", "term"].includes(valueKey)) {
      setValid("exists");
    }
  };

  const updateCalendar = (updatedCourse) => {
    if (updatedCourse.weekdays.indexOf(1) >= 0) {
      setValid("weekdays");
    }
    if (
      (updatedCourse.day_exceptions &&
        updatedCourse.day_exceptions.length > 0) ||
      updatedCourse.no_day_exceptions
    ) {
      setValid("holidays");
    }
    updateCourse(updatedCourse);
  };

  const updateCourseDates = (valueKey, value) => {
    const updatedCourse = CourseDateUtils.updateCourseDates(
      state.course,
      valueKey,
      value
    );
    setState((prevState) => ({
      ...prevState,
      course: updatedCourse,
    }));
  };

  const handleChange = (value, key) => {
    const updatedCourse = { ...state.course, [key]: value };
    setState((prevState) => ({
      ...prevState,
      course: updatedCourse,
      tempCourseId: CourseUtils.generateTempId(updatedCourse),
    }));
    updateCourse(updatedCourse);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!isValid) return;
    initiateConfirm();
  };

  const handleDelete = () => {
    deleteCourse(course.id);
  };

  return (
    <Modal>
      <form onSubmit={handleSubmit}>
        <TextInput
          value={state.course.title}
          onChange={(e) => handleChange(e.target.value, "title")}
        />
        <DatePicker
          selectedDate={state.course.start}
          onChange={(date) => handleChange(date, "start")}
        />
        <TextAreaInput
          value={state.course.description}
          onChange={(e) => handleChange(e.target.value, "description")}
        />
        <Calendar
          value={state.course.calendar}
          onChange={(cal) => handleChange(cal, "calendar")}
        />
        <button type="submit">Submit</button>
        <button type="button" onClick={handleDelete}>
          Delete
        </button>
      </form>
    </Modal>
  );
};

CourseClonedModal.propTypes = {
  course: PropTypes.object.isRequired,
  initiateConfirm: PropTypes.func.isRequired,
  deleteCourse: PropTypes.func.isRequired,
  updateCourse: PropTypes.func.isRequired,
  updateClonedCourse: PropTypes.func.isRequired,
  currentUser: PropTypes.object.isRequired,
  setValid: PropTypes.func.isRequired,
  setInvalid: PropTypes.func.isRequired,
  isValid: PropTypes.bool.isRequired,
  activateValidations: PropTypes.func.isRequired,
  firstErrorMessage: PropTypes.string,
  courseCreationNotice: PropTypes.string,
};

export default CourseClonedModal;
