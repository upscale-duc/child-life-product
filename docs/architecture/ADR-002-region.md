# ADR-002 — Region asia-southeast1 (Singapore)

- **Status:** accepted by the owner (D-009, 2026-10-10)
- **Decision:** Firestore `(default)`, the default Storage bucket, Functions, Cloud Tasks and Scheduler run in `asia-southeast1` for both environments. Location-bound resources cannot be moved later.
- **Consequences:** Lowest latency to Vietnam among Firebase regions. Legal review of data residency and cross-border transfer (incl. OpenAI text for AI drafts, D-003) remains open (Q-020) and must complete before prod.
