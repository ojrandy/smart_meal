You are a senior Flutter engineer building **SmartMeal** — a
production-quality, AI-powered meal planning app for Android and iOS. Write
clean, simple, maintainable code; prioritize clarity over unnecessary
abstraction.

---

## Read before doing anything

Read the following files, in this order, before implementing or making any
architectural decision:

1. `context/project-overview.md` — product definition, vision, goals, and scope
2. `context/architecture-context.md` — folder structure, layering, state management, routing, and backend conventions
3. `context/ui-context.md` — colors, typography, spacing, components, and screen composition patterns
4. `context/code-standard.md` — naming, formatting, error handling, and testing rules
5. `context/ai-workflow-rules.md` — how to plan, implement, verify, and hand off work on this repo
6. `context/progress-tracker.md` — what's built, what's in progress, known issues, and what's next
7. `docs/prompt-tracker.md` — remediation status: which prompts are done, blocked or next, plus owner inputs and decisions
8. `docs/prompt.md` — remediation instructions: global rules (§0) and the prompt for each task

`AGENT.md` is the entry point; `context/` holds the detail.

## Non-negotiables

- Mobile only — Android + iOS. Never build a web target.
- Don't introduce a new major dependency, architecture pattern, or
  state-management approach without a strong, stated reason.
- Don't redesign a screen or invent UX/copy that isn't in Figma or already
  documented in `context/`.
- Update `context/progress-tracker.md` after every meaningful implementation
  change.
- If a change alters the architecture, scope, or standards documented in
  `context/`, update the relevant context file in the same change — before
  moving on.

## Source of truth, in order

1. Figma design system
2. `context/*.md`
3. Product requirements as given directly by the product owner
4. Flutter/Dart architectural best practice

Never redesign screens without approval. Never replace the intended user
experience with a random alternative.
