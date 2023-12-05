import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

// Permissions slide
const Permissions = ({ currentUser, returnToParam }) => {
  const [isHovered, setIsHovered] = useState(false);

  let slide;

  if (currentUser.instructor) {
    slide = (
      <div className="intro permissions">
        <h1>Permissions</h1>
        <p>
          Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages when:
        </p>
        <ul>
          <li>you submit a Wikipedia classroom assignment or make edits to your course page</li>
          <li>you add or remove someone from a course</li>
          <li>you assign articles to students</li>
          <li>you send public messages to students</li>
        </ul>
        <p>All course content you contribute to this website will be freely available under the <a href="https://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
        <Link onMouseEnter={() => setIsHovered(true)} onMouseLeave={() => setIsHovered(false)} to={{ pathname: '/onboarding/finish', search: `?return_to=${returnToParam}` }} className="button border inverse-border">
          Finish <i className={`icon3 ${isHovered ? 'icon-rt_arrow_purple' : ' icon-rt_arrow'}`} />
        </Link>
      </div>
    );
  } else {
    slide = (
      <div className="intro permissions">
        <h1>Permissions</h1>
        <p>
          Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages to:
        </p>
        <ul>
          <li>set up a sandbox page where you can practice editing</li>
          <li>adjust your account preferences to enable VisualEditor</li>
          <li>add a standard message on your userpage so that others know what course you are part of</li>
          <li>add standard messages to the Talk pages of articles you´re editing or reviewing</li>
          <li>update your course´s wiki page when you join the course or choose an assignment topic</li>
        </ul>
        <p>All course content you contribute to this website will be freely available under the <a href="https://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
        <Link onMouseEnter={() => setIsHovered(true)} onMouseLeave={() => setIsHovered(false)} to={{ pathname: '/onboarding/finish', search: `?return_to=${returnToParam}` }} className="button border inverse-border">
          Finish <i className={`icon3 ${isHovered ? 'icon-rt_arrow_purple' : ' icon-rt_arrow'}`} />
        </Link>
      </div>
    );
  }

  return slide;
};

Permissions.propTypes = {
  currentUser: PropTypes.object,
  returnToParam: PropTypes.string
};

export default Permissions;
