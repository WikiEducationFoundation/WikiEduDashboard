import { submitReviewRequestAlert } from '../../../../actions/alert_actions';

export default (assignment, course) => {
  const reviewBibliography = course.review_bibliography;

  if (course.stay_in_sandbox) {
    return [
      completeBibliography(assignment, reviewBibliography),
      completeOutline(assignment),
      createInSandbox(assignment),
      expandYourDraft(assignment),
      prepareForMainspace(assignment)
    ];
  }
  if (course.no_sandboxes) {
    return [
      completeBibliography(assignment, reviewBibliography),
      completeOutline(assignment),
      makeYourEdits(assignment)
    ];
  }

  return [
    completeBibliography(assignment, reviewBibliography),
    completeOutline(assignment),
    createInSandbox(assignment),
    expandYourDraft(assignment),
    moveYourWork(assignment)
  ];
};

const completeBibliography = (assignment, reviewBibliography) => {
  const bibliographyStep = {
    title: 'Complete your bibliography',
    content: 'Compile a list of reliable and verifiable secondary sources for the subject you\'ll be contributing to.',
    status: 'not_yet_started',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#complete-your-bibliography'
      },
      {
        title: 'Bibliography',
        path: `${assignment.sandboxUrl}/Bibliography?veaction=edit&preload=Template:Dashboard.wikiedu.org_bibliography`,
        external: true
      },
      {
        title: 'Outline',
        path: `${assignment.sandboxUrl}/Outline?veaction=edit&preload=Template:Dashboard.wikiedu.org_outline`,
        external: true
      }
    ]
  };
  if (reviewBibliography) {
    bibliographyStep.buttonLabel = 'Ready for review';
    bibliographyStep.stepAction = submitReviewRequestAlert;
  }
  return bibliographyStep;
};

const completeOutline = (assignment) => {
  const outlineStep = {
    title: 'Outline your changes',
    content: 'Create an outline of the changes you plan to make, based on the sources from your bibliography.',
    status: 'bibliography_complete',
    trainings: [
      {
        title: 'Outline',
        path: `${assignment.sandboxUrl}/Outline?veaction=edit&preload=Template:Dashboard.wikiedu.org_outline`,
        external: true
      }
    ]
  };

  return outlineStep;
};

const createInSandbox = (assignment) => {
  let url = assignment.sandboxUrl;
  if (Features.wikiEd) {
    url += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_draft_template';
  }

  return {
    title: 'Create in the sandbox',
    content: 'In your designated sandbox, begin to sketch out your contribution.',
    status: 'in_progress',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#create-in-the-sandbox'
      },
      {
        title: 'Sandbox',
        path: url,
        external: true
      }
    ]
  };
};

const expandYourDraft = (assignment) => {
  return {
    title: 'Expand your draft',
    content: 'Continue to build your contribution and prepare it for the article main space.',
    status: 'ready_for_review',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#expand-your-draft'
      },
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      }
    ]
  };
};

const moveYourWork = (assignment) => {
  return {
    title: 'Move your work',
    content: 'It\'s time to move your contribution into the article main space and make your work live!',
    status: 'ready_for_mainspace',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#move-your-work'
      },
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      },
      {
        title: 'Article',
        path: assignment.article_url,
        external: true
      }
    ]
  };
};

const prepareForMainspace = (assignment) => {
  return {
    title: 'Final checks',
    content: 'Use the quality checklist to make sure your work meets all the requirements to become a live Wikipedia article. If it does, it will be moved live after the end of the course.',
    status: 'ready_for_mainspace',
    trainings: [
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      },
      {
        title: 'Article',
        path: assignment.article_url,
        external: true
      }
    ]
  };
};

const makeYourEdits = (assignment) => {
  return {
    title: 'Make your edits',
    content: 'It\'s time to start improving the live article!',
    status: 'ready_for_live_edits',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#editing-live'
      },
      {
        title: 'Article',
        path: assignment.article_url,
        external: true
      }
    ]
  };
};
