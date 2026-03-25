---
name: vep
description: Work with KubeVirt Virtualization Enhancement Proposals (VEPs) - read, summarize, check status, or find related PRs
argument-hint: <VEP number, issue URL, or search query>
allowed-tools: Bash, Read, WebFetch, Grep, Glob, Agent
---

# /vep - KubeVirt Virtualization Enhancement Proposal

Work with VEPs (Virtualization Enhancement Proposals) from the [kubevirt/enhancements](https://github.com/kubevirt/enhancements) repository.

## What is a VEP?

A VEP is a formal proposal for a major feature or change in KubeVirt. VEPs live in the `kubevirt/enhancements` repository and follow a structured lifecycle:

- **Proposal**: Author opens a PR to `kubevirt/enhancements` with a VEP document under `veps/<owning-sig>/<feature-name>/vep.md`.
- **Tracking Issue**: Author opens an issue on `kubevirt/enhancements` using the VEP tracker template to track progress through Alpha, Beta, and GA stages.
- **SIG Ownership**: Each VEP is owned by a single SIG (Compute, Network, or Storage), even if it spans multiple SIGs. All SIGs must sign off.
- **Release Targeting**: VEPs are targeted to specific releases during planning phases, with Enhancement Freeze (EF) and Code Freeze (CF) deadlines.
- **Feature Gates**: Features are guarded by feature gates until GA.

### VEP Document Structure

Each VEP document includes: Overview, Motivation, Goals, Non Goals, User Stories, Design, API Examples, Alternatives, Scalability, Update/Rollback Compatibility, Functional Testing Approach, and Graduation Requirements (Alpha/Beta/GA).

### VEP Tracking Issue Structure

Each tracking issue includes: Primary contact, Current Feature Stage, Feature Gate name, Responsible SIGs, Enhancement link (to VEP doc), Timeline with release targets, and checklists of VEP PRs, Code PRs, and Docs PRs for each stage.

### Key Labels

- SIG labels (e.g., `sig/compute`, `sig/network`, `sig/storage`)
- Target labels for release targeting
- `approved-vep` label on kubevirt/kubevirt PRs that implement a VEP

## Usage

```
/vep <VEP number or issue URL or search query>
```

## Instructions

### If given a VEP number or issue URL

1. **Fetch the tracking issue**: Use `gh api repos/kubevirt/enhancements/issues/<N>` to get the tracking issue details.

2. **Read the VEP document**: Find the "Enhancement link" in the issue body pointing to a markdown file (e.g., `veps/sig-compute/feature-name/vep.md`). Fetch it with `gh api repos/kubevirt/enhancements/contents/<path> --jq '.content' | base64 -d`.

3. **Summarize**: Provide a structured summary including:
   - Title and owning SIG
   - Current stage (Alpha/Beta/GA)
   - Feature gate name
   - Overview and goals (concise)
   - Target release versions
   - Status of Code PRs, VEP PRs, and Docs PRs (merged/open/missing)
   - Any blockers or outstanding items

4. **Find related PRs on kubevirt/kubevirt**: Search for PRs implementing this VEP:
   ```
   gh api 'search/issues?q=repo:kubevirt/kubevirt+is:pr+label:approved-vep+<VEP-keywords>' --jq '.items[] | "\(.number) \(.state) \(.title)"'
   ```

### If given a search query

Search for VEPs matching the query:
```
gh api 'search/issues?q=repo:kubevirt/enhancements+is:issue+label:kind/enhancement+<query>' --jq '.items[] | "\(.number) \(.title) \(.state)"'
```

Then summarize the matching VEPs.

### If no argument is given

List currently open/tracked VEPs:
```
gh api 'search/issues?q=repo:kubevirt/enhancements+is:issue+is:open+label:kind/enhancement' --jq '.items[] | "\(.number) \(.title)"'
```