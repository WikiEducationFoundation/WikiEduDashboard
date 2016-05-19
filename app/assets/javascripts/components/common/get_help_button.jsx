import React from 'react';
import Expandable from '../high_order/expandable.cjsx';
import UserStore from '../../stores/user_store.coffee';

const getState = () =>
  ({
    contentExperts: UserStore.getFiltered({ content_expert: true }),
    programManagers: UserStore.getFiltered({ program_manager: true })
  })
;

const GetHelpButton = React.createClass({
  displayName: 'GetHelpButton',

  propTypes: {
    key: React.PropTypes.string,
    current_user: React.PropTypes.object,
    open: React.PropTypes.func,
    is_open: React.PropTypes.bool
  },

  mixins: [UserStore.mixin],

  getInitialState() {
    return getState();
  },

  getKey() {
    return this.props.key;
  },

  stop(e) {
    return e.stopPropagation();
  },

  storeDidChange() {
    return this.setState(getState());
  },

  render() {
    let programManagers;
    let contentExperts;
    let helpers;

    contentExperts = this.state.contentExperts.map((user) => {
      return (
        <span key={user.username}>
          <a href={`mailto:${user.email}`}>{user.username}</a> (Content Expert)
          <br />
        </span>
      );
    });

    if (this.props.current_user.role > 0) {
      programManagers = this.state.programManagers.map((user) => {
        return (
          <span key={user.username}>
            <a href={`mailto:${user.email}`}>{user.username}</a> (Program Manager)
            <br />
          </span>
        );
      });
    }

    if (programManagers || contentExperts) {
      helpers = (
        <p>
          If you still need help, reach out to your Wikipedia Content Expert:
          <br />
          {contentExperts}
          {programManagers}
        </p>
      );
    }

    return (
      <div className="pop__container">
        <button className="dark button small" onClick={this.props.open}>Get Help</button>
        <div className={`pop${this.props.is_open ? ' open' : ''}`}>
          <div className="pop__padded-content">
            <p>
              <strong>
                Hi, if you need help with your Wikipedia assignment, you've come
                to the right place!
              </strong>
            </p>

            <form target="_blank" action="/ask" acceptCharset="UTF-8" method="get">
              <input name="utf8" type="hidden" defaultValue="✓" />
              <input type="text" name="q" id="q" defaultValue="" placeholder="Search Help Forum" />
              <button type="submit">
                <i className="icon icon-search"></i>
              </button>
            </form>

            <p>
              You may also refer to our interactive training modules and
              external resources for help with your assignment.
            </p>

            <p>
              <a href="/training" target="blank">Interactive Training</a><br />
              <a href="#" target="blank">FAQ</a>
            </p>

            {helpers}
          </div>
        </div>
      </div>
    );
  }
}
);

export default Expandable(GetHelpButton);
