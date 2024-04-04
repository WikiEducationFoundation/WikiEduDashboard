import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const WEEKDAYS_LONG = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const WEEKDAYS_SHORT = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

const localeUtils = {
  formatWeekdayLong: function (weekday) {
    return WEEKDAYS_LONG[weekday];
  },
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

const WeekdayPicker = createReactClass({
  propTypes: {
    className: PropTypes.string,
    style: PropTypes.object,
    tabIndex: PropTypes.number,

    ariaModifier: PropTypes.string,
    modifiers: PropTypes.object,

    locale: PropTypes.string,
    localeUtils: PropTypes.shape({
      formatWeekdayShort: PropTypes.func.isRequired,
      formatWeekdayLong: PropTypes.func.isRequired
    }),

    onWeekdayClick: PropTypes.func,
    onWeekdayMouseEnter: PropTypes.func,
    onWeekdayMouseLeave: PropTypes.func,
  },

  getModifiersForDay(weekday, modifierFunctions) {
    const modifiers = [];
    if (modifierFunctions) {
      Object.keys(modifierFunctions).forEach((modifier) => {
        const func = modifierFunctions[modifier];
        if (func(weekday)) {
          modifiers.push(modifier);
        }
      });
    }
    return modifiers;
  },

  focusPreviousDay(dayNode) {
    const body = dayNode.parentNode.parentNode.parentNode.parentNode;
    const dayNodes = body.querySelectorAll('.rdp-Weekday:not(.rdp-Weekday_outside)');
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
  },

  focusNextDay(dayNode) {
    const body = dayNode.parentNode.parentNode.parentNode.parentNode;
    const dayNodes = body.querySelectorAll('.rdp-Weekday:not(.rdp-Weekday_outside)');
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
  },

  // Event handlers
  handleDayKeyDown(e, day, modifiers) {
    e.persist();
    switch (e.keyCode) {
      case keys.LEFT:
        e.preventDefault();
        e.stopPropagation();
        this.focusPreviousDay(e.target);
        break;
      case keys.RIGHT:
        e.preventDefault();
        e.stopPropagation();
        this.focusNextDay(e.target);
        break;
      case keys.ENTER:
      case keys.SPACE:
        e.preventDefault();
        e.stopPropagation();
        if (this.props.onWeekdayClick) {
          this.handleWeekdayClick(e, day, modifiers);
        }
        break;
      default:
        // no default
    }
  },

  handleWeekdayClick(e, weekday, modifiers) {
    e.persist();
    this.props.onWeekdayClick(e, weekday, modifiers);
  },

  handleWeekdayMouseEnter(e, weekday, modifiers) {
    e.persist();
    this.props.onWeekdayMouseEnter(e, weekday, modifiers);
  },

  handleWeekdayMouseLeave(e, weekday, modifiers) {
    e.persist();
    this.props.onWeekdayMouseLeave(e, weekday, modifiers);
  },

  renderWeekDays() {
    const weekdays = [];
    for (let i = 0; i < 7; i += 1) {
      weekdays.push(this.renderWeekday(i));
    }
    return (
      <div className="rdp-Month">
        <div className="rdp-Weekdays">
          <div>
            {weekdays}
          </div>
        </div>
      </div>
    );
  },

  renderWeekday(weekday) {
    const { locale, modifiers: modifierFunctions } = this.props;

    let className = 'rdp-Weekday';
    let modifiers = [];

    if (modifierFunctions) {
      const customModifiers = this.getModifiersForDay(weekday, modifierFunctions);
      modifiers = [...modifiers, ...customModifiers];
    }

    className += modifiers.map(modifier => ` ${className}_${modifier}`).join('');

    const ariaSelected = modifiers.indexOf(this.props.ariaModifier) > -1;

    const {
      onWeekdayClick,
      onWeekdayMouseEnter,
      onWeekdayMouseLeave,
    } = this.props;

    let tabIndex = null;
    if (onWeekdayClick) {
      tabIndex = -1;
      // Focus on the first day of the week
      if (weekday === 0) {
        tabIndex = this.props.tabIndex;
      }
    }

    let onClick = null;
    if (onWeekdayClick) {
      onClick = e => this.handleWeekdayClick(e, weekday, modifiers);
    }
    let onMouseEnter = null;
    if (onWeekdayMouseEnter) {
      onMouseEnter = e => this.handleWeekdayMouseEnter(e, weekday, modifiers);
    }
    let onMouseLeave = null;
    if (onWeekdayMouseLeave) {
      onMouseLeave = e => this.handleWeekdayMouseLeave(e, weekday, modifiers);
    }

    return (
      <button
        key={weekday} className={className} tabIndex={tabIndex}
        aria-pressed={ariaSelected}
        onClick= {onClick}
        onKeyDown={e => this.handleDayKeyDown(e, weekday, modifiers)}
        onMouseEnter={onMouseEnter}
        onMouseLeave= {onMouseLeave}
      >
        <span title={localeUtils.formatWeekdayLong(weekday, locale)}>
          {localeUtils.formatWeekdayShort(weekday, locale)}
        </span>
      </button>
    );
  },

  render() {
    const { locale, style, tabIndex } = this.props;
    let className = `WeekdayPicker DayPicker rdp_${locale}`;

    if (!this.props.onWeekdayClick) {
      className = `${className} WeekdayPicker_InteractionDisabled`;
    }
    if (this.props.className) {
      className = `${className} ${this.props.className}`;
    }

    return (
      <div
        className={className}
        role="widget"
        style={style}
        tabIndex={tabIndex}
      >
        {this.renderWeekDays()}
      </div>
    );
  }
});

export default WeekdayPicker;
