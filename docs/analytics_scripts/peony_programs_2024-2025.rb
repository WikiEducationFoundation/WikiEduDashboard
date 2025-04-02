# Script to pull tabular data requested by Fiona Romero (Director, Community Programs at WMF)

# Desired format:
# Title	Institution	Start	End	Facilitator	Wiki																
# WikiSoCal	QoL Experiences	2016-01-01 09:00:00 UTC	2067-01-01 07:59:00 UTC	DrMel
# WikiSoCal	QoL Experiences	2016-01-01 09:00:00 UTC	2067-01-01 07:59:00 UTC		enwiki
# WikiSoCal	QoL Experiences	2016-01-01 09:00:00 UTC	2067-01-01 07:59:00 UTC		wikidatawiki
# PERSONNES FORMEES 2017	WMFr	2016-12-31 23:00:00 UTC	2049-12-31 23:00:00 UTC	Mathieu Denel WMFr
# PERSONNES FORMEES 2017	WMFr	2016-12-31 23:00:00 UTC	2049-12-31 23:00:00 UTC		frwiki
# PERSONNES FORMEES 2017	WMFr	2016-12-31 23:00:00 UTC	2049-12-31 23:00:00 UTC		wikidatawiki
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC	Shai-WMIL
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC	Itamar-WMIL
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC	Ruti-WMIL
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC	Shnili-WMIL
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC		hewiki
# TLV University, Science Oriented Youth - Alpha Program - Cycle C	tlv university	2016-11-17 22:00:00 UTC	2030-12-31 22:00:00 UTC		wikidatawiki

# courses that happened in 2024-2025

courses = Course.where('start < ?', '2026-01-01'.to_date).where('end > ?', '2023-12-31'.to_date); nil

headers = ['Slug', 'Title', 'Institution', 'Start', 'End', 'Facilitator', 'Wiki']

data = [headers]

courses.each do |course|
  next if course.private
  row = [
    course.slug,
    course.title,
    course.school,
    course.start.to_s,
    course.end.to_s
  ]

  course.instructors.each do |facilitator|
    facilitator_row = row + [facilitator.username, nil]
    data << facilitator_row
  end

  course.wikis.each do |wiki|
    wiki_row = row + [nil, wiki.domain]
    data << wiki_row
  end
end; nil

CSV.open("/home/ragesoss/peony_2024-2025_data.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end; nil
