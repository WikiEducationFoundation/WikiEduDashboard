## Adding new handout options

Unlike the rest of the assignment wizard which is mainly configured in the respective `wizard.yml` and `content.yml` files, the selection of handouts has special treatment in the WizardTimelineManager to dynamically create a block with all selected handouts.

To add a new handout to the wizard output:

1. Add a new wikiedu.org shortlink that points directly to the handout file. (This is done in the `.htaccess` file of wikiedu.org.)
2. Add a wizard option that includes a `logic` entry to represent selecting the new handout, like `logic: art_history_handout`.
3. Add that new logic entry as the key in the `HANDOUTS` hash in `lib/wizard_timeline_manager.rb`, with a value following the pattern of other entries.
4. Create a timeline using the updated wizard, and confirm that it inserts the expected handout with a working link.
