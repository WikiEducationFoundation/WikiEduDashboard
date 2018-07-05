#!/usr/bin/python3

# requirements:
# pip3 install mwapi mwreverts jsonable mwtypes

# see https://pythonhosted.org/mwreverts/api.html#module-mwreverts.api

import mwapi
import mwreverts.api
import csv

total = 0
reverted = 0
missing = 0
errors = 0

# generate a CSV of revision IDs with revision_ids_for_campaign.rb

with open('/home/sage/dumps/spring_2018_revs.csv', 'r') as f:
  reader = csv.reader(f)
  revs = list(reader)

session = mwapi.Session("https://en.wikipedia.org")

# This handles a few revisions per second, so expect this to take many hours for a large set of revisions.
for rev in revs:
   try:
     status = mwreverts.api.check(session, rev[0])
   except KeyError: # this error means the revision couldn't be found, likely deleted
     missing += 1
     status = [None, None]
   except: # handles other, rare errors with some revisions
     errors += 1
     status = [None, None]

   total += 1
   if status[1] is not None:
     reverted += 1


   print(f"total: {total}")
   print(f"revert rate: {reverted / total}") # mainspace revert rate
   print(f"errors: {errors}") # should be very low
   # Missing count should be very close to the deleted revision count from revision_ids_for_campaign.rb
   # It's probably more accurate because it will account for deletions that happened after the dashboard
   # stopped updating, 30 days after course end.
   print(f"missing: {missing}")
