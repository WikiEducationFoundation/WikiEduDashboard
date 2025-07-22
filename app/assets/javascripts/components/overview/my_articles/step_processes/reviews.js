export default assignment => ([
  {
    title: 'Read the article',
    content: 'Read the article and complete the Peer Review Exercise. This will help prepare you for providing feedback.',
    status: 'reading_the_article',
    trainings: [
      {
        title: 'Peer Review Exercise',
        path: '../../../training/students/peer-review',
        external: true
      }
    ]
  },
  {
    title: 'Provide feedback',
    content: 'Assess your classmate\'s proposed contributions.',
    status: 'providing_feedback',
    trainings: [
      {
        title: 'Bibliography',
        path: `${assignment.sandboxUrl}/Bibliography`,
        external: true
      },
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      },
      {
        title: 'Peer Review',
        path: `${assignment.sandboxUrl}/${assignment.username}_Peer_Review?veaction=edit&preload=Template:Dashboard.wikiedu.org_peer_review`,
        external: true
      }
    ]
  },
  {
    title: 'Mark as complete',
    content: 'Let your classmate know that you\'ve reviewed their work by posting on their talk page so they can begin to incorporate your feedback into their draft.',
    status: 'post_to_talk',
    trainings: [
      {
        title: 'Sandbox',
        path: assignment.sandboxUrl,
        external: true
      }
    ]
  }
]);
