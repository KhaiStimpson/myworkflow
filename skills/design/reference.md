# Why the design pass works this way

Background for `design`. Not loaded unless something here is in question.

## Why there is no extraction step

An earlier version had a subagent inline the app shell's stylesheets and copy real component
markup into a scratch file, so mockups rendered in the real design system. It worked, and it was
the most expensive thing the design pass did — tens of thousands of tokens of CSS per pass — for
a fidelity that never decided anything. What gets judged on a mockup is layout, hierarchy and
behaviour at two breakpoints; what binds implementation is the decision record, which already
names the real components by file path. So the mockup is deliberately plain, and fidelity moved
to the one place that is actually built from.

## Why three variants, at both breakpoints

Three is the number confirmed explicitly and repeatedly, across `andrew-crm`, `sqlviewer` and
`dump-debugger`. Two invites a false binary; four dilutes the reading. The variants must be
meaningfully different — three spacings of one idea is one variant presented three times.

Mobile is not a follow-up round because it has been asked for unprompted four separate times.
Shipping desktop-only and waiting to be corrected is a known, repeated, avoidable cost.

## Why the record outranks the artifact

"actually lets not use them just use the css etc and components as a reference." The mockup shows
proportion and behaviour; it is not markup to copy. What binds implementation is the written
record — reused components by real file path, new components with their justification, and
rejected choices with reasons so they are not quietly reintroduced three sessions later.

## Why a stable URL

Rounds accumulate. An artifact chased across five URLs cannot be compared against itself, and the
version the human approved stops being findable. Republish to the same URL every round.
