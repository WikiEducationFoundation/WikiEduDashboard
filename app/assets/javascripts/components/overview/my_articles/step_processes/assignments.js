export default assignment => ([
  {
    title: 'Complete your bibliography',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam felis mi, aliquam ac dui non, gravida convallis massa.',
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
      }
    ]
  },
  {
    title: 'Create in the sandbox',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam felis mi, aliquam ac dui non, gravida convallis massa.',
    status: 'in_progress',
    trainings: [
      {
        title: 'Related Training Modules',
        path: 'resources#create-in-the-sandbox'
      },
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      }
    ]
  },
  {
    title: 'Expand your draft',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam felis mi, aliquam ac dui non, gravida convallis massa.',
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
  },
  {
    title: 'Move your work',
    content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam felis mi, aliquam ac dui non, gravida convallis massa.',
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
  }
]);
