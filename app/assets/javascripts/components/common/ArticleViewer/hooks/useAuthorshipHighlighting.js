import React, { useEffect, useRef, useState } from 'react';
import { forEach, union } from 'lodash-es';

// Components
import ArticleViewerLegend from '@components/common/ArticleViewer/authorship/ArticleViewerLegend.jsx';

// Helpers
import AuthorshipURLBuilder from '@components/common/ArticleViewer/authorship/AuthorshipURLBuilder';
import AuthorshipAPI from '@components/common/ArticleViewer/authorship/AuthorshipAPI';

// Constants
import colors from '@components/common/ArticleViewer/authorship/colors';

/*
  WhoColor authorship-highlighting feature for the ArticleViewer shell.

  This hook owns everything WhoColor-specific: fetching the WikiWho coloring HTML
  (with retry/backoff/cooldown), post-processing its per-token spans into
  `highlightedHtml`, resolving MediaWiki user IDs, reconciling contributors whose
  edits couldn't be highlighted, and building the per-user legend.

  It plugs into ArticleViewerShell as that shell's injected highlight feature: the
  shell drives it through `parsedSettle` (bumped whenever the shell's parsed-article
  fetch settles, after redirect resolution) and `revisionId`, and renders what this
  hook returns — `{ html, legend, buttonLabel, pending }`. The shell knows nothing
  about authorship; a different feature (e.g. claim verification) can supply its own
  hook with the same contract.
*/
const useAuthorshipHighlighting = ({
  article, users, assignedUsers, showArticleFinder,
  isOpen, revisionId, parsedSettle, fetchArticleDetails, requestTitleVerification,
}) => {
  const [highlightedHtml, setHighlightedHtml] = useState(null);
  const [whoColorHtml, setWhoColorHtml] = useState(null);
  const [usersState, setUsersState] = useState([]);
  const [userIdsFetched, setUserIdsFetched] = useState(false);
  const [unhighlightedContributors, setUnhighlightedContributors] = useState([]);
  const [whoColorFailed, setWhoColorFailed] = useState(false);
  const [failureMessage, setFailureMessage] = useState(null);
  const [pending, setPending] = useState(false);

  const isFirstRevisionRender = useRef(true);

  const isWhocolorLang = () => {
    // Supported languages for https://wikiwho-api.wmcloud.org as of 2023-05-15
    // See https://github.com/wikimedia/wikiwho_api/blob/main/wikiwho_api/settings_wmcloud.py#L21
    const supported = ['ar', 'de', 'en', 'es', 'eu', 'fr', 'hu', 'id', 'it', 'ja', 'nl', 'pl', 'pt', 'tr'];
    return supported.includes(article.language) && article.project === 'wikipedia';
  };

  // This takes the extended_html from the whoColor API, and replaces the span
  // annotations with ones that are more convenient to style in React.
  // The matching and replacing of spans is tightly coupled to the span format
  // provided by the whoColor API: https://github.com/wikimedia/wikiwho_api
  const highlightAuthors = () => {
    let html = whoColorHtml;
    if (!html) { return; }
    // Array to store user IDs whose contributions couldn't be highlighted
    const unHighlightedUsers = [];

    forEach(usersState, (user, i) => {
      // Move spaces inside spans, so that background color is continuous
      html = html.replace(/ (<span class="editor-token.*?>)/g, '$1 ');

      // Replace each editor span for this user with one that includes their
      // username and color class.
      const prevHtml = html;
      const colorClass = colors[i];
      const styledAuthorSpan = `<span title="${user.name}" class="editor-token token-editor-${user.userid} ${colorClass}`;
      const authorSpanMatcher = new RegExp(`<span class="editor-token token-editor-${user.userid}`, 'g');
      html = html.replace(authorSpanMatcher, styledAuthorSpan);

      if (prevHtml !== html) {
        user.activeRevision = true;
      } else {
        // If highlighting failed , store the un-highlighted user's ID in the editorsID array
        unHighlightedUsers.push(user.userid);
      }
    });

    // Check if there are any editors whose contributions couldn't be highlighted
    if (unHighlightedUsers.length) {
      // If there are unhighlighted editors, call the function to check their contributions in wikitext metadata
      usersContributionExists(unHighlightedUsers);
    } else {
      const status = 'No Unhighlighted Contributors';
      // Set the status of the unhighlightedContributors state to display in the UI
      setUnhighlightedContributors([status]);
    }
    setHighlightedHtml(html);
    setPending(false);
  };

  // Function to check if contributions of unhighlighted editors exist in the wikitext metadata
  const usersContributionExists = (usersID) => {
    // Create a URL builder and API instance for fetching wikitext metadata
    const builder = new AuthorshipURLBuilder({ article });
    const api = new AuthorshipAPI({ builder });

    // Fetch wikitext metadata for the current article revision
    api.fetchWikitextMetaData()
       .then((response) => {
         // Extract the tokensForRevision data from the response
         const { tokensForRevision } = response;

         // Iterate through the list of user IDs whose contributions couldn't be highlighted
         usersID.forEach((userID) => {
          // Find a token in the metadata with a matching editor ID
          const foundToken = tokensForRevision.find(token => token.editor === userID.toString());

          // If a token with a matching editor ID is found, it means the user has a contribution
          // in the current revision's wikitext
          if (foundToken) {
            // Add the user ID to the unhighlightedContributors state to display in the UI
            setUnhighlightedContributors(x => [...x, userID]);
          } else {
            const status = `No Contributions Found in this current version for User ID', ${userID}`;
            // If the user ID doesn't have a contribution in the current revision's wikitext,
            // add a message to the unhighlightedContributors state to display in the UI
            setUnhighlightedContributors(x => [...x, status]);
          }
        });
      }).catch((error) => {
      setFailureMessage(error.message);
    });
  };

  const fetchWhocolorHtml = () => {
    const builder = new AuthorshipURLBuilder({ article });
    const api = new AuthorshipAPI({ builder });
    setPending(true);
    api.fetchWhocolorHtml(revisionId)
      .then((response) => {
        setWhoColorHtml(response.html);
      }).catch((error) => {
        setWhoColorFailed(true);
        setFailureMessage(error.message);
        setPending(false);
        // Only trigger title verification for failures that may be caused by title changes.
        // If WhoColor is simply not ready/available (our API throws a specific message),
        // do NOT re-verify the title to avoid infinite re-requests.
        const unavailablePattern = /^Request failed after \d+ attempts/;
        const cooldownPattern = /WhoColor temporarily unavailable; retry later/;
        if (unavailablePattern.test(error.message) || cooldownPattern.test(error.message)) {
          requestTitleVerification(false);
        } else {
          // For other errors (eg, 404s after redirects), allow one title verification pass
          requestTitleVerification(true);
        }
      });
  };

  // These are mediawiki user ids, and don't necessarily match the dashboard
  // database user ids, so we must fetch them by username from the wiki.
  const fetchUserIds = () => {
    /*
      if articleViewer is accessed through Students/Editors tab, a combination
      of both assignedUsers and users will be passed to the URLBuilder.
      However, if the articleViewer is accessed through any other tab. Only the users prop will be passed
      to the URLBuilder as the assignedUsers prop would be undefined.
      In this case, the users prop will be combined with an empty array.
     */
    const allUsers = union(assignedUsers || [], users);
    const builder = new AuthorshipURLBuilder({ article, users: allUsers });
    const api = new AuthorshipAPI({ builder });
    api.fetchUserIds()
      .then((response) => {
        response.query.users.forEach((user) => {
          user.name = decodeURIComponent(user.name);
          user.activeRevision = false;
        });
        setUsersState(response.query.users);
        setUserIdsFetched(true);
      }).catch((error) => {
        setFailureMessage(error.message);
        setWhoColorFailed(true);
      });
  };

  // Load contributor usernames when the viewer opens without them, then fetch the
  // MediaWiki user IDs once usernames are available. The `[isOpen, users]` effect
  // is deliberately not finder-guarded (matching the legacy behavior where finder
  // mode still resolves user IDs so highlighting works without a legend).
  useEffect(() => {
    if (isOpen && !users && !showArticleFinder) {
      fetchArticleDetails();
    }
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && users && !userIdsFetched) {
      fetchUserIds();
    }
  }, [isOpen, users]);

  // The shell fetches the parsed article (resolving redirects). Once it settles we
  // fetch WhoColor for the (now-resolved) title, or mark a failure if the parse failed.
  useEffect(() => {
    if (!parsedSettle) { return; }
    if (parsedSettle.ok) {
      // Clear any prior failure so a recovery (e.g. after title verification) returns
      // the legend to its loading state before the fresh data arrives.
      setWhoColorFailed(false);
      if (isWhocolorLang()) {
        fetchWhocolorHtml();
      }
    } else {
      setWhoColorFailed(true);
      setFailureMessage(parsedSettle.message);
    }
  }, [parsedSettle?.id]);

  // Wait for whocolor API to return the raw HTML before highlighting it
  useEffect(() => {
    if (whoColorHtml) {
      highlightAuthors();
    }
  }, [whoColorHtml]);

  // On a revision toggle, drop the previous coloring; the shell's parsed refetch
  // bumps parsedSettle, which re-fetches WhoColor for the new revision.
  useEffect(() => {
    if (isFirstRevisionRender.current) {
      isFirstRevisionRender.current = false;
      return;
    }
    setHighlightedHtml(null);
    setWhoColorHtml(null);
    setUnhighlightedContributors([]);
  }, [revisionId]);

  // Determine the Article Viewer Legend status based on what information
  // has returned from various API calls.
  let legend = null;
  if (!showArticleFinder) {
    let legendStatus;
    if (highlightedHtml && unhighlightedContributors.length) {
      legendStatus = 'ready';
    } else if (whoColorFailed) {
      legendStatus = 'failed';
    } else if (isWhocolorLang()) {
      legendStatus = 'loading';
    }

    legend = (
      <ArticleViewerLegend
        article={article}
        users={usersState}
        colors={colors}
        status={legendStatus}
        failureMessage={failureMessage}
        unhighlightedContributors={unhighlightedContributors}
      />
    );
  }

  const buttonLabel = isWhocolorLang()
    ? I18n.t('articles.show_current_version_with_authorship_highlighting')
    : null;

  return {
    html: highlightedHtml || whoColorHtml || null,
    legend,
    buttonLabel,
    pending,
  };
};

export default useAuthorshipHighlighting;
