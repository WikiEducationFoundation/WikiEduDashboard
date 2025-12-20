# Article Viewer Accessibility Improvements

# Enhancing Screen Reader Usability and Focus Behavior for “Scroll to User Edits”

The main goal of the following changes is to enable keyboard and screen reader users to successfully jump to highlighted revisions within the Article Viewer.

1. Making the “Scroll to User Edits” Button Accessible
Previously, the scroll-to-edit control was implemented as a clickable icon that was not keyboard-focusable
or labeled as a button. As a result, jumping between edits was not screen reader-friendly.

Solution:
The scroll buttons (in article_viewer_legend.jsx) were converted to actual aria-labeled <button> elements. The roles of the buttons were clearly indicated within the labels passed to screenreaders.



2. Ensuring Focus Moves to the Scrolled-To Content
Upon clicking the jump to edits button, the page is visually "scrolled" down to the next highlighted edit, but does not update screen reader focus.
This caused screen readers to stay stuck on the button/ on old content, confusing users about whether the navigation actually happened.

Solution:
The scrollTo() function in the ArticleScroll.js file was adjusted to return the DOM element representing the scrolled-to paragraph.Now, article_viewer_legend.jsx can call .focus() so assistive technology tracks the scroll target.
These changes were also reflected in the article_viewer_legend.jsx to set tabindex="-1", which makes any element programmatically focusable.