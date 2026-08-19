# Why the design pass works this way

Background for `design`. Not loaded unless something here is in question.

## Why extraction beats reconstruction

The failure mode in a brownfield mockup is not CSS, it is markup. Extracted CSS comes out exact;
hand-rolled markup renders components invisible — white on transparent is the classic. So the
extractor is told to **copy** real component markup rather than reconstruct it from class names,
and "zero unresolved local references" is the success test, because an unresolved reference means
the extractor misread the project rather than that the project is missing something.

Whatever the application loads at document head **is** the design system, by definition. Not what
a style guide says it is, not what a component library exports — what actually loads, in the
order it loads.

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
