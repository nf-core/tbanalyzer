# Agent review — tbanalyzer (pre-draft, warrant-first skeleton)

**Date:** 2026-06-30
**Subject:** `writeup/manuscript/src/index.qmd` — _tbanalyzer: a unified nf-core pipeline …_ (OUP Bioinformatics **Application Note**; warrant-first **skeleton**, validation §3 deliberately TODO).
**Method:** four enriched agents via the Toulmin lens — `argument-architect`, `claim-evidence-auditor`, `paper-structurer`, `peer-reviewer` (OUP Bioinformatics). The peer-reviewer read the actual repo (`workflows/magmanf.nf`, `tests/`, `docs/`, `CHANGELOG.md`).

---

## Headline

Two good-news findings: the **warrant is well-formed** and the **anchor's framing firewall holds** (the executor isn't leaked, MAGMA/XBS internals are cited-not-described, nf-core compliance is demoted to a method choice) — writing warrant-first did its job. But the panel surfaced **one finding that contests the core contribution** and a set of execution/hygiene gates that make the paper unsubmittable as-is (P(desk-reject) ≈ 90%).

## ⚠️ The contribution-breaking finding (resolve first)

**The implementation maintains TWO samplesheet schemas — which contradicts the headline "one samplesheet drives both modes."** `workflows/magmanf.nf:62` reads `SAMPLESHEET_VALIDATION(file(params.magma_input_samplesheet ?: params.input …))`, with an inline note that "MAGMA uses its own CSV format (study, sample, library, …, r1, r2) … a different schema." The warrant — _one samplesheet, no reformatting_ — is undercut by the code itself, and a reviewer who reads the repo will say so. **Either** unify the schema so a single CSV drives both modes (preferred — it makes the contribution literally true), **or** reframe to "a unified pipeline with a shared `--input` entry point and mode-specific column schemas, eliminating two separate codebases and execution environments" (weaker but honest) and rewrite the abstract + §1 warrant to match. Settle this before any validation runs.

## Blocking before submission (OUP)

1. **Run `--mode magma` end-to-end** on a named multi-sample MTBC cohort → **Table 1** (samples, joint-genotyped SNP/SV counts, resistance summary, walltime/mem). One mode validated is not a "spread"; OUP reviewers run the software. This single item gates the hard-gate, proves the warrant, and fills §3.
2. **Real Zenodo DOI** — the README still shows `10.5281/zenodo.XXXXXXX`; that's a literal editorial-office return. Tag v1.0 first.
3. **A real test suite + public CI.** The sole `tests/default.nf.test` is mode-agnostic (FastQC/MultiQC + one MTBseq file), runs on self-hosted runners (not publicly verifiable), and has **no `--mode magma` coverage at all**. Add an nf-test tagged `magma` on public CI + a cross-mode test that runs both modes from one samplesheet.

## Argumentation — `argument-architect`

The warrant is correctly formed and contribution-bearing (the abstraction, not the wrapped callers). One refinement: add a sentence making explicit that **§3 _establishes_ the warrant across both modes**, not merely illustrates one. The conclusion's "demonstrates" must stay **"presumably"** until both modes are shown. The dual-pipeline-overhead _grounds_ are absent — quantify the samplesheet-field incompatibility (a field-diff table) and lower "removes" → "reduces". Pre-empt the **"why not a bash script chaining both tools?"** rebuttal in §1 (answer: shared QC + unified input + provenance + containerisation).

## Structure — `paper-structurer`

Right shape for an Application Note. Three design decisions **before** validation runs: (A) settle the **canonicalisation procedure** for the byte-identical claim — use **record-count + topology (Robinson-Foulds = 0)** as a _shared supplementary method across XBS / MAGMA-v2 / tbanalyzer_; (B) **resolve MAGMA authorship → then pick the §3.2 dataset** (TORCH preferred; PRJEB7727 again isn't independent of §3.1); (C) add a **samplesheet schema table to §2** (this is also the fix for the contribution-breaking finding above). Move the §1 warrant **out of the block-quote into prose** (OUP strips block-quotes).

## Claim & bibliography integrity — `claim-evidence-auditor`

- The **`[TODO release URL]`** placeholder + the README placeholder DOI are blockers.
- **"No prior tool unifies the two paradigms" is uncited** — back the landscape with a structured comparator **table** (rows: MTBseq, TB-Profiler, MAGMA, Bactopia-TB, nf-core/pathogensurveillance, tbanalyzer; cols: per-sample / joint-genotyping / SV / nf-core / single-samplesheet), and use orphans `@petit2020bactopia` (contrast) + `@walker2015wgs` (WGS-surveillance opener).
- **GATK/DELLY cited at original versions** — check the full Zotero collection for Van der Auwera 2013 (GATK Best Practices) / DELLY2; cite the _update_ TB-Profiler (v5/v6) not the 2019 paper.
- The **byte-identical canonicalisation procedure is undefined** — publish it as the shared supplementary method.

## Repository hygiene (OUP reviewers check GitHub first)

`docs/output.md` is template boilerplate (no MTBseq/MAGMA outputs documented); `CHANGELOG.md` is an empty `v1.0dev`; the README Introduction/Credits carry unfilled `<!-- TODO nf-core -->` comments. **Title says "nf-core pipeline"** — confirm `nf-co.re/tbanalyzer` doesn't 404, or qualify to "built on the nf-core v4 template." Adoption: name ≥1 institution beyond SU with a run log.

## Anti-claim leaks

"clinical surveillance" is in the title but the paper isn't clinically certified — add a one-line research-tool disclaimer. The abstract should say "**via MTBseq**" (not bare "drug-resistance profiling", which reads as a TB-Profiler-replacement claim) and "**DELLY-based** structural-variant detection" (so SV isn't credited to tbanalyzer). Add a **resistance-call concordance** vs TB-Profiler (PRJEB7727) to back "complement, not replace". Address **VQSR defaults for MTBC** (cite MAGMA's parameter choices or justify).

## Verdict + do-these-first

P(desk-reject) ≈ 90% as-is, driven by undemonstrated MAGMA mode + the placeholder DOI. In order: **(1) run `--mode magma` → Table 1; (2) resolve the samplesheet-schema contradiction (unify or reframe); (3) tag v1.0 + real Zenodo DOI.** Then the comparator table, the canonicalisation method, and the repo-hygiene items. Venue choice (OUP Application Note) is correct.
