# PR: Warn when `position_jitterdodge()` groups are inflated beyond fill

## Problem

`position_jitterdodge()` silently produces misaligned points when the point
layer maps discrete aesthetics beyond the `fill` used for dodging.

```r
# Points land in wrong dodge slots — no error, no warning
ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = mpg > 20),
             position = position_jitterdodge())
```

**Root cause:** `add_group()` computes implicit groups from the interaction of
*all* discrete aesthetics. Adding `colour` (logical) inflates groups from
`cyl x am` (matching boxplot) to `cyl x am x colour` (not matching). The
`pos_dodge()` strategy then distributes points across more slots than exist in
the boxplot, causing horizontal misalignment.

**Current fix:** `aes(group = am)` — but this requires understanding ggplot2's
implicit grouping mechanism, which is non-obvious even to experienced users.

## What this PR does

**1. Targeted warning** — `setup_params()` now compares unique group counts
against unique `fill` counts per x-position. When groups exceed fills, it emits:

```
! Dodge groups are larger than the number of `fill` values.
i This can happen when additional discrete aesthetics (e.g., `colour`)
  inflate the implicit grouping.
i Set `aes(group = <fill variable>)` to align points with the dodged layer.
```

The warning uses the existing `vec_unique`/`vec_group_id`/`tabulate` pattern
already present in the function (lines 63-65) and follows the `cli::cli_warn()`
conventions used throughout the position code (`position-dodge.R:121`,
`position-stack.R:266`).

**Does not fire when:**
- User already set `group = <fill_var>` (groups = fills)
- Only `fill` is mapped (no inflation)
- `fill` is absent or continuous
- No discrete aesthetics besides fill exist

**2. Documentation** — New `@section Interaction with grouping:` explains the
mechanism and fix, with a worked example showing both the pitfall and solution.

## Testing

4 new tests in `test-position-jitterdodge.R`:
- Warning fires when colour inflates groups beyond fill
- Silent with explicit `group = fill_var`
- Silent with fill only
- Silent without fill

## Rationale

- **Zero API change** — no new parameters, no behavior change
- **Surgical** — 20 lines of warning logic reusing existing patterns
- **High impact** — directly addresses the most common confusion with this function
- **Consistent** — follows the same warning style as `position_dodge()` and `position_stack()`
