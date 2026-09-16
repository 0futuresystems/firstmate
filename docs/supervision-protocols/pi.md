Mode: Pi extension background wake.

When this session owns supervision and no legacy away daemon flag is active:
1. Drain first with `bin/fm-wake-drain.sh`.
   After handling all emitted wakes and reconciling open decisions and unread status lines, run the exact `--ack-through` command printed as `WAKE_ACK_REQUIRED`; until then the work remains durable for idempotent re-handling after interruption.
2. Pi primaries must start through `__FM_PI_LAUNCHER__`.
   The launcher disables cwd-dependent discovery, loads the watcher before the turn-end guard by absolute path, and binds both loaded markers to that launcher identity without global installation or project-trust dependence.
3. The watcher extension establishes and verifies the first cycle after this Pi process owns the Firstmate lock, then keeps the child attached to the live Pi process and owns every successor launch.
   Never run `bin/fm-watch-arm.sh` through Pi's bash tool because that foreground arm can wedge the agent and bypasses extension-owned cleanup.
4. Ordinary same-process session replacement (`/new`, `/resume`, `/fork`, reload) retires only the prior generation and automatically establishes one cycle for the replacement generation.
   The generation-owner contract and in-flight actionable-close handoff live in `.pi/extensions/fm-primary-pi-watch.ts`.
5. After an actionable child close, the extension rechecks session-lock ownership and verifies one successor before it delivers the follow-up wake; its bounded fallback is defined in `docs/watcher-continuity.md`.
6. Ordinary work, turn completion, and ordinary signal, stale, check, heartbeat, or other wake handling: do not call `fm_watch_arm_pi` because continuity is extension-owned rather than model-memory-owned.
7. An unexpected child close enters bounded exponential retry, and an exhausted retry or lost session lock is surfaced as a watcher failure instead of disappearing.
8. Missing, failed, or unhealthy cycle only: drain queued wakes, inspect the failure text, and restart through `__FM_PI_LAUNCHER__` if the extension markers are absent or do not match the locked process, file hashes, and launcher identity.
   A redundant call while the extension owns an arm child or scheduled retry is an ownership-based `watcher: unchanged` no-op, not an independent health claim.
9. Never use shell `&` for watcher supervision.
   The arm mechanism above is extension-owned, not a model tool call, but a manual recovery probe that backgrounds, pipes, or bundles the arm is denied automatically by the PreToolUse seatbelt (`bin/fm-arm-pretool-check.sh`, wired into the turn-end guard extension at `__FM_PI_TURNEND_EXT__`).

The supervision branch is default-on (docs/pi-supervision-branch.md): whenever this session owns the fleet lock and no legacy away daemon flag is active, the watcher extension hands eligible task-local rows from ordinary actionable wakes, plus selected fleet-wide heartbeat reviews, to the in-process supervision branch while main-only rows remain queued for this conversation; the away-posture record alone leaves this path active.
Decision-owned signal and stale routing, including whole-batch precedence and the independent heartbeat exception, is owned by [docs/pi-supervision-branch.md](../pi-supervision-branch.md#components-and-their-owners).
A no-change heartbeat outcome explicitly reported with `task=fleet` and `silent=true` is delivered silently with no rendered note, while every other routine outcome returns as an appended, rendered note that leads with ⛵ then the dim outcome text.
A captain-facing outcome instead appears as one exact, sequence-keyed visible transcript entry, and then arrives in this conversation as one hidden supervision processing request listing each `[seq N] task: summary` it covers.
That request is the one turn in which MAIN processes the outcome: give the captain a visible response where one is due, answer or escalate a decision, act on a blocker or failure, or record that no further action is needed, then call the `fm_branch_processed` tool with the highest sequence the request listed, exactly once.
Only that call closes the outcome; an unrelated, empty, or paraphrased answer leaves it open, and the current unprocessed sequence set is presented again at the next run boundary and at session start until it is acknowledged.
The persisted entry is already the captain-visible record, so MAIN must not re-emit it verbatim merely because it appeared.
Before MAIN steers, controls lifecycle, or cleans up a task, claim its lease with `bin/fm-lease.sh claim <task>` and release it afterwards; a refused claim means the branch is acting on that task right now.
This conversation still receives every other fleet-wide or unresolvable wake, the branch's wakes when it is unavailable or a legacy away daemon flag is active, and every watcher-failure alarm regardless, so the arm and repair contract above is unchanged.
Treat the merged fleet event as already handled for fleet operations: MAIN must not re-drain, re-run, or acknowledge it.
Separately, MAIN applies judgment about whether and how to surface, summarize, reference, or incorporate a merged sailboat outcome in the captain conversation; event ownership does not decide the conversational treatment.
Read the durable outcome store with the fm_branch_outcomes tool when the captain asks what happened.

The turn-end guard extension lives at `__FM_PI_TURNEND_EXT__`.
The watcher extension lives at `__FM_PI_EXT__`.
Both are tracked, project-local `.pi/extensions/*.ts` files that Pi auto-discovers once the project is trusted; `bin/fm-session-start.sh` reports when the running Pi session has not loaded both required extensions.
