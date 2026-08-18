# Why a slice works this way

Background for `work`. Not loaded unless something here is in question.

## Why "stop and ask" is the load-bearing rule

It is the single most repeated instruction in every loop prompt in the corpus, and it is what
makes unattended running safe. Guessing produces work that has to be unpicked, which costs more
than the interruption ever would. A loop that stops with a question has cost one iteration; a
loop that guesses wrong for six iterations has cost six, plus the unpicking.

## Why the integration branch exists

"Merge should only be to our feature branch as well i dont want this in dev until all code is
done and i have reviewed." The topology follows directly: ticket branches off the integration
branch, merged back `--no-ff` so each slice stays individually walkable, and one PR at the end.

The `--no-ff` matters more than it looks. A fast-forward merge destroys the boundary between
slices, which is exactly the thing that makes the final PR reviewable slice by slice instead of
as one unreadable diff.

## Why unrelated diffs get flagged rather than swept in

Silently broadening the blast radius is the correction issued most often in the corpus — "don't
ship harness", "ok undo the temp ci changes". The rule is not about tidiness. A commit whose
stated scope and actual scope differ cannot be reviewed against its own description, and cannot
be reverted cleanly.

## Why ~400 lines, and why it is not a hard gate

Small reviewable slices are what is wanted; batch-at-the-end is what actually happened — roughly
thirty tickets merged unreviewed into one integration branch, against the stated wish "i dont
wnat to review 2000 lines of code i want to review small horizontal testable slices". Read the
batching as a workaround for per-ticket review being unaffordable by hand, not an endorsement.

So the number gets **stated** rather than enforced: a slicing error that stays invisible repeats,
and one that gets named does not.

## Why migrations are singled out

A data-safety rule, graded Strong. Re-scaffolding or squashing migrations destroys the record of
what has already been applied to a database that exists. It is stack-specific — EF, in practice —
but the consequence is not recoverable, which is why it sits in the body and not here.
