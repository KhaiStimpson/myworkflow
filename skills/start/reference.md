# Why the front door works this way

Background for `start`. Not loaded unless something here is actually in question.

## The veto is the safety mechanism, not the analysis

The whole protection of the small routes is that the proposal is fast to veto. That is why the
announcement is three lines and why route 0 does not stop for confirmation: a wrong route costs
one character to correct, so optimism is affordable in a way it would not be if correcting cost
a paragraph.

Route 3 is the exception because chartering a map is an expensive commitment — the cost of being
wrong there is not one character, it is a session.

## Why uncertainty biases up

A task mis-routed *down* produces work that has to be unpicked: code where a plan was wanted,
a plan where a decision was wanted. A task mis-routed *up* costs a plan file nobody needed. The
asymmetry is large and it runs one way.

## Why the design axis is evaluated separately from size

Historically this is the most common shape of the work and the easiest one to mis-route: a UI
request that lands in route 1 produces code where three mockups were wanted. Size and visual
under-determination are genuinely independent — a one-line change can be a design question and a
two-thousand-line refactor can have no visual content at all.

## Why questions are rationed

Long question sequences get abandoned, and an abandoned front door leaves nothing behind. The
evidence is explicit and repeated: "can we do multiple of these at one im getting tired of
answering", "OK i cant answer any more right now". Hence: batch, cap, and prefer announcing a
decision that can be vetoed over asking a question that must be answered.

## Why the probe rule is worded the way it is

Naming the boundary a probe tests *before running it* is what separates investigation from
reading the repo for comfort. Two probes is enough to settle a routing decision; more than that
means the question is not really about routing.

## The four routes map to Orchestrator's four lanes

Deliberately. Orchestrator specifies the automated version of this same routing model —
conductors, spawned sessions, context packs, status files. Keeping the routes identical means
nothing learned by hand here is thrown away when it is automated.
