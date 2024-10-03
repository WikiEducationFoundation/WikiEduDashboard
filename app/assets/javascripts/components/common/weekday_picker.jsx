import React from 'react';
import PropTypes from 'prop-types';

const WEEKDAYS_LONG = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const WEEKDAYS_SHORT = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

const localeUtils = {
  // eslint-disable-next-line object-shorthand
  formatWeekdayLong: function (weekday) {
    return WEEKDAYS_LONG[weekday];
  },
  // eslint-disable-next-line object-shorthand
  formatWeekdayShort: function (weekday) {
    return WEEKDAYS_SHORT[weekday];
  }
};

const keys = {
  LEFT: 37,
  RIGHT: 39,
  ENTER: 13,
  SPACE: 32
};

const WeekdayPicker = ({
  className: componentClassName,
  style,
  tabIndex,

  ariaModifier,
  modifiers,

  locale,
  onWeekdayClick,
  onWeekdayMouseEnter,
  onWeekdayMouseLeave,
}) => {
  const getModifiersForDay = (weekday, modifierFunctions) => {
    const resultModifiers = [];
    if (modifierFunctions) {
      Object.keys(modifierFunctions).forEach((modifier) => {
        const func = modifierFunctions[modifier];
        if (func(weekday)) {
          resultModifiers.push(modifier);
        }
      });
    }
    return resultModifiers;
  };

  const focusPreviousDay = (dayNode) => {
    const body = dayNode.parentNode.parentNode.parentNode.parentNode;
    const dayNodes = body.querySelectorAll('.DayPicker-Weekday:not(.DayPicker-Weekday--outside)');
    let nodeIndex;
    for (let i = 0; i < dayNodes.length; i += 1) {
      if (dayNodes[i] === dayNode) {
        nodeIndex = i;
        break;
      }
    }
    if (nodeIndex !== 0) {
      dayNodes[nodeIndex - 1].focus();
    }
  };

  const focusNextDay = (dayNode) => {
    const body = dayNode.parentNode.parentNode.parentNode.parentNode;
    const dayNodes = body.querySelectorAll('.DayPicker-Weekday:not(.DayPicker-Weekday--outside)');
    let nodeIndex;
    for (let i = 0; i < dayNodes.length; i += 1) {
      if (dayNodes[i] === dayNode) {
        nodeIndex = i;
        break;
      }
    }

    if (nodeIndex !== dayNodes.length - 1) {
      dayNodes[nodeIndex + 1].focus();
    }
  };

  const handleWeekdayClick = (e, weekday, modifiersProp) => {
    e.persist();
    onWeekdayClick(e, weekday, modifiersProp);
  };

  const handleDayKeyDown = (e, weekday, modifiersProp) => {
    e.persist();
    switch (e.keyCode) {
      case keys.LEFT:
        e.preventDefault();
        e.stopPropagation();
        focusPreviousDay(e.target);
        break;
      case keys.RIGHT:
        e.preventDefault();
        e.stopPropagation();
        focusNextDay(e.target);
        break;
      case keys.ENTER:
      case keys.SPACE:
        e.preventDefault();
        e.stopPropagation();
        if (onWeekdayClick) {
          handleWeekdayClick(e, weekday, modifiersProp);
        }
        break;
      default:
        // no default
    }
  };

  const handleWeekdayMouseEnter = (e, weekday, modifiersProp) => {
    e.persist();
    onWeekdayMouseEnter(e, weekday, modifiersProp);
  };

  const handleWeekdayMouseLeave = (e, weekday, modifiersProp) => {
    e.persist();
    onWeekdayMouseLeave(e, weekday, modifiersProp);
  };

  const renderWeekday = (weekday) => {
    let dayClassName = 'DayPicker-Weekday';
    let customModifiers = [];

    if (modifiers) {
      const propModifiers = getModifiersForDay(weekday, modifiers);
      customModifiers = [...customModifiers, ...propModifiers];
    }

    dayClassName += customModifiers.map(modifier => ` ${dayClassName}--${modifier}`).join('');

    const ariaSelected = customModifiers.indexOf(ariaModifier) > -1;

    let tabIndexValue = null;
    if (onWeekdayClick) {
      tabIndexValue = -1;
      if (weekday === 0) {
        tabIndexValue = tabIndex;
      }
    }

    const onClickHandler = onWeekdayClick ? e => handleWeekdayClick(e, weekday, customModifiers) : null;
    const onMouseEnterHandler = onWeekdayMouseEnter ? e => handleWeekdayMouseEnter(e, weekday, customModifiers) : null;
    const onMouseLeaveHandler = onWeekdayMouseLeave ? e => handleWeekdayMouseLeave(e, weekday, customModifiers) : null;

    return (
      <button
        key={weekday} className={dayClassName} tabIndex={tabIndexValue}
        aria-pressed={ariaSelected}
        onClick={onClickHandler}
        onKeyDown={e => handleDayKeyDown(e, weekday, customModifiers)}
        onMouseEnter={onMouseEnterHandler}
        onMouseLeave={onMouseLeaveHandler}
      >
        <span title={localeUtils.formatWeekdayLong(weekday)}>
          {localeUtils.formatWeekdayShort(weekday)}
        </span>
      </button>
    );
  };

  const renderWeekDays = () => {
    const weekdays = [];
    for (let i = 0; i < 7; i += 1) {
      weekdays.push(renderWeekday(i));
    }
    return (
      <div className="DayPicker-Month">
        <div className="DayPicker-Weekdays">
          <div>
            {weekdays}
          </div>
        </div>
      </div>
    );
  };

  let finalClassName = `WeekdayPicker DayPicker DayPicker--${locale}`;

  if (!onWeekdayClick) {
    finalClassName = `${finalClassName} WeekdayPicker--InteractionDisabled`;
  }
  if (componentClassName) {
    finalClassName = `${finalClassName} ${componentClassName}`;
  }

  return (
    <div
      className={finalClassName}
      role="widget"
      style={style}
      tabIndex={tabIndex}
    >
      {renderWeekDays()}
    </div>
  );
};

WeekdayPicker.propTypes = {
  className: PropTypes.string,
  style: PropTypes.object,
  tabIndex: PropTypes.number,

  ariaModifier: PropTypes.string,
  modifiers: PropTypes.object,

  locale: PropTypes.string,
  onWeekdayClick: PropTypes.func,
  onWeekdayMouseEnter: PropTypes.func,
  onWeekdayMouseLeave: PropTypes.func,
};

export default WeekdayPicker;
