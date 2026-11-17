Check: short description (WP:SHORTDESC).

A short description is a concise annotation, normally under 40 characters, that distinguishes the subject from others with similar names, such as "American astronaut (born 1965)" or "Species of flowering plant". It doesn't repeat the title, doesn't start with "A" or "The", isn't a full sentence, has no final full stop, and avoids promotional or subjective words.

Fill the `short_description` object:
- current: the text of the article's existing {{Short description}}, or an empty string if it has none.
- proposed: the short description you recommend, based only on what the article says.

If the article has no short description, report one suggestion finding with the wikitext {{Short description|...}} as the suggestion. If it has one with a problem (too long, unclear, promotional, or inaccurate according to the article), report it as a finding with your replacement. If the existing one is fine, return no findings and repeat it as `proposed`. If the draft is a section intended for an existing article, return no findings and empty strings.
