Wikimedia blocks edits from broad IP ranges for many cloud server providers (eg, Linode). These may be a combination of global and local blocks. To work around these, work with wiki admins to make sure the relevant local blocks allow edits from logged-in users; as long as it's an anon-only block, Dashboard edits won't be affected. If the relevant block is global, one solution is to disable the global lock on the local wiki, and (if necessary) create a local block of the same range that does not apply to logged-in users.

For example:
* Changing a local rangeblock to be anon-only: https://en.wikipedia.org/w/index.php?title=Special:Log/block&page=User%3A45.79.0.0%2F16
* Locally disabling a global block: https://en.wikipedia.org/w/index.php?title=Special:Log&logid=117955646


The Dashboard also may make enough edits to exceed the normal rate limits (eg, for new account creation). Exemptions must be configured for the Dashboard to operate normally. Here are some relevant Phabricator tickets for requests to add or update the Wikimedia site configuration to allow Dashboard to bypass rate-limited edits:
* https://phabricator.wikimedia.org/T126541
* https://phabricator.wikimedia.org/T151823
* https://phabricator.wikimedia.org/T283096

