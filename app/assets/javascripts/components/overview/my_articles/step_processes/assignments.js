
export default [
  {
    title: 'Gather your sources',
    content: 'Remember that you need several reliable sources to establish notability.',
    status: 'not_yet_started',
    trainings: [
      {
        title: 'Wikipedia policies',
        path: 'training/students/wikipedia-essentials'
      },
      {
        title: 'Evaluating articles and sources',
        path: 'training/students/evaluating-articles'
      },
      {
        title: 'Finding your article',
        path: 'training/students/finding-your-article'
      },
    ]
  },
  {
    title: 'Scaffold your article',
    content: 'Create sections as appropriate, then fill them in. Remember to cite as you write.',
    status: 'in_progress',
    trainings: [
      {
        title: 'How to edit',
        path: 'training/students/how-to-edit'
      },
      {
        // need to conditionally change this if working in groups
        title: 'Drafting in the sandbox',
        path: 'training/students/drafting-in-sandbox'
      },
      {
        title: 'Adding citations',
        path: 'training/students/sources'
      },
    ]
  },
  {
    title: 'Expand your draft',
    content: 'Implement updates of your own or from a peer review. Then, review the Quality Checklist in preparation to move your work live.',
    status: 'ready_for_review',
    trainings: [
      {
        title: 'Plagiarism & copyrights',
        path: 'training/students/plagiarism'
      }
    ]
  },
  {
    title: 'Move your work',
    content: 'Remove your Sandbox template. Then, move your work live. Review the Quality Checklist as you clean up your work.',
    status: 'ready_for_mainspace',
    trainings: [
      {
        title: 'Move your work',
        path: 'training/students/moving-to-mainspace'
      }
    ]
  }
];
