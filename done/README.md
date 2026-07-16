# done/ — finished (deployed + verified) packages

The Coordinator moves a package folder here **after** BNKR deploys it and its matching
`deployed/<name>.json` is verified on-chain. The active queue (repo root + `TASKS-FOR-BNKR.md`)
stays clean — only PENDING work lives there. This is the "shipped" shelf of the staging workflow.

**Flow:**
```
staging (root package)
  → BNKR deploys + pushes deployed/<name>.json
  → Coordinator verifies on-chain
  → package moved HERE + task checked ✅ in TASKS-FOR-BNKR.md + committed
```
