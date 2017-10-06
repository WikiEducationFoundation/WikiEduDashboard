[Back to README](../README.md)

## Future Improvements & Features

### "What's Changed"
We would like to present users with a summary of important items that have changed in the last week and, if possible, since they last signed in. This is not feasible without a robust caching layer.

Redis can provide a [low-level key/value caching implementation](http://aurelien-herve.com/blog/2015/01/21/awesome-low-level-caching-for-your-rails-app/) for this feature and would allow us to remove the caching columns from our MySQL database.

#### Updating
- Whenever a `revision` is saved the corresponding `user` is `touched`. 
- Whenever a `user` is saved all corresponding `courses_users` are `touched`. 
- Whenever a `courses_users` is saved the corresponding `course` is `touched`. 

#### Fetching
- Whenever a `course` needs to display total revisions it checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it gets the number of revisions from each `courses_users`. 
- Each `courses_users` checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it gets the number of revisions from each `user`. 
- Each `user` checks for the existence of a redis key using its current `updated_at` value. If that doesn't exist, it calculates and saves a revision count.


Example: articles store data snapshots in an ordered Redis set with the key `article.<ID>.<DATA_TYPE>`. Whenever a new revision is added to that article a new entry is added to the ordered set with the `score` being a timestamp and the `value` being the added view or character count. Later, when we want to see the number of views between two dates, we can query this ordered set using those dates and sum all values returned.