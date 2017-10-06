# frozen_string_literal: true

# Routine for finding the winners of the 2016 student earning research incentive
# drawing, who will receive prizes

# the relevant surveys
pre_assessment = Survey.find(3)
post_assessment = Survey.find(4)
optional_survey = Survey.find(6)

# Users who completed both pre and post assessments are eligible for one entry
eligible_for_one = pre_assessment.send(:respondents) & post_assessment.send(:respondents)

# Users who also complete the optional survey afterwards are eligible for a second entry
eligible_for_another = eligible_for_one & optional_survey.send(:respondents)

# Users in both groups will be represented twice in the drawing list
drawing_list = eligible_for_one + eligible_for_another

# Get emails for random winners
drawing_list.sample(5).map(&:email)
