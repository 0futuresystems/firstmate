Mode: Pi extension background wake.

When this session owns supervision and away mode is not active:
1. Drain first with `bin/fm-wake-drain.sh`.
2. Pi primaries must start through `bin/fm-pi.sh` (or `FM_PI_HARNESS=pi-signed bin/fm-pi.sh`). It disables cwd-dependent discovery, loads the watcher before the turn-end guard by absolute path, and binds both loaded markers to that launcher identity without global installation or project-trust dependence.
3. The watcher extension establishes and verifies the first cycle after this Pi process owns the Firstmate lock, then keeps the child attached to the live Pi process and owns every successor launch.
   Never run `bin/fm-watch-arm.sh` through Pi's bash tool because that foreground arm can wedge the agent and bypasses extension-owned cleanup.
4. Ordinary same-process session replacement (`/new`, `/resume`, `/fork`, reload) retires only the prior generation and automatically establishes one cycle for the replacement generation.
   The generation-owner contract lives in `.pi/extensions/fm-primary-pi-watch.ts`.
5. After an actionable child close, the extension rechecks session-lock ownership and verifies one successor before it delivers the follow-up wake; its bounded fallback is defined in `docs/watcher-continuity.md`.
6. Ordinary work, turn completion, and ordinary signal, stale, check, heartbeat, or other wake handling: do not call `fm_watch_arm_pi` because continuity is extension-owned rather than model-memory-owned.
7. An unexpected child close enters bounded exponential retry, and an exhausted retry or lost session lock is surfaced as a watcher failure instead of disappearing.
8. Missing, failed, or unhealthy cycle only: drain queued wakes, inspect the failure text, and restart through the selected launcher (`bin/fm-pi.sh`, or `FM_PI_HARNESS=pi-signed bin/fm-pi.sh`) if the extension markers are absent or do not match the locked process, file hashes, and launcher identity.
   A redundant call while the extension owns an arm child or scheduled retry is an ownership-based `watcher: unchanged` no-op, not an independent health claim.
9. Never use shell `&` for watcher supervision.
   The arm mechanism above is extension-owned, not a model tool call, but a manual recovery probe that backgrounds, pipes, or bundles the arm is denied automatically by the PreToolUse seatbelt (`bin/fm-arm-pretool-check.sh`, wired into the turn-end guard extension at `__FM_PI_TURNEND_EXT__`).

The turn-end guard extension lives at `__FM_PI_TURNEND_EXT__`.
The watcher extension lives at `__FM_PI_EXT__`.
Both are tracked, project-local `.pi/extensions/*.ts` files loaded by `bin/fm-pi.sh`; `bin/fm-session-start.sh` reports a missing integration as a supervision failure.
