---
name: jj-split
description: >-
  Decomposes a large, monolithic Jujutsu (jj) commit into a series of atomic,
  reviewable, and test-verified units. Use when needing to decompose a large
  commit.
---

# Splitting a Jujutsu (jj) Commit

<instructions>

1.  **Prerequisites & Planning**:

    -   Identify the target `COMMIT_TO_SPLIT` and its immediate `PARENT_COMMIT`.

    -   Run `jj diff --stat -r <COMMIT_TO_SPLIT>` to get a clean list of
        modified files.

    -   Plan the logical split units (e.g., specific files or logical code
        blocks like "Refactor utility", "Add tests", "Implement feature").

2.  **Decomposition Cycle (Execution)**: For each logical unit in order:

    -   **Initialize**: Start a new commit on top of the correct parent.

    -   For the very first unit: `jj new <PARENT_COMMIT> -m "Description of Unit 1"`

    -   For subsequent units: `jj new -m "Description of Unit N"`

    -   **Populate (Whole Files)**: If entire files belong to this unit, use `jj
        restore --from <COMMIT_TO_SPLIT> path/to/file1 path/to/file2`.

    -   **Populate (Partial Files)**: If only *part* of a file belongs to this
        unit:

        1.  `jj restore --from <COMMIT_TO_SPLIT> path/to/file`

        2.  Edit the file to revert the changes that do not belong to this unit
            yet.

    -   **Dependencies**: If a unit introduces a new dependency/API, commit the
        definition first, and commit the usage in a subsequent step.

    -   **Validate**: Run the relevant test suite for the project (e.g., `npm test`,
        `cargo test`, `go test`, `pytest`) to ensure this specific unit is valid
        and passes tests.

    -   **Retroactive Fixes**: If a mistake is discovered in a previous unit
        (e.g., Unit 1) while on Unit 2:

        -   Create a temporary child: `jj new <UNIT_1_ID>`

        -   Apply the fix.

        -   Squash it: `jj squash`

        -   Return to your working tip: `jj new <UNIT_2_ID>`

    -   **Validation**: After creating all split commits, verify the final state
        matches the original:

        -   Compare: `jj diff --from <COMMIT_TO_SPLIT> --to @`

        -   Success Condition: The output should be **empty** or only contain
            minimal, intentional differences.

        -   Fix Misses: If there are accidental changes, fix them in the working
            copy and run `jj absorb` to automatically distribute the fixes into
            the relevant previous commits.

</instructions>

<technical-details>

### JJ Split Quick Reference

-   **List Changes**: `jj diff --stat -r <COMMIT>`

-   **Restore State**: `jj restore --from <COMMIT> <PATHS>`

-   **Check Difference**: `jj diff --from <COMMIT_TO_SPLIT> --to @`

-   **Distribute Fixes**: `jj absorb`

</technical-details>

<constraints>

-   **Independent Validity**: Every single commit in the resulting chain MUST
    build and pass its associated unit tests.

-   **No Drastic Changes**: Do not diverge from the intended changes in the
    original commit when fixing test failures.

-   **No Residuals**: The original monolithic commit should be replaced entirely
    by the new chain. If it corresponds to an existing change (CL/PR), do NOT
    abandon it; `jj` handles moving the change along automatically.

-   **NEVER abandon a change that already exists**: This is never needed because
    `jj` handles moving the change along automatically.

</constraints>

<examples>

<example>

### Splitting Unit 'X' into Refactor + Feature

1.  `jj new X- -m "Refactor internal API"`

2.  `jj restore --from X internal/api.cc`

3.  Run tests (e.g., `cargo test`)

4.  `jj new -m "Implement new RPC handler"`

5.  `jj restore --from X handler/rpc.cc`

6.  Run tests (e.g., `cargo test`)

7.  `jj diff --from X --to @` (Verify empty diff)

</example>

</examples>
