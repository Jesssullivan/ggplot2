Warn when `position_jitterdodge()` groups are inflated beyond fill

Closes #XXXX.

## Motivation

`position_jitterdodge()` silently misaligns points when additional discrete aesthetics (e.g., `colour`) are mapped in the point layer. The implicit group becomes finer than the `fill`-based dodge of the boxplot, but no diagnostic is emitted. The workaround (`aes(group = <fill variable>)`) requires understanding the implicit grouping mechanism, which is non-obvious.

```r
# Points land in wrong dodge slots — no error, no warning
ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs)),
             position = position_jitterdodge(seed = 1))
```

## Changes

**Warning** (`R/position-jitterdodge.R`): In `setup_params()`, when `fill` is present and discrete, compare the number of unique groups per x-position against the number of unique fill values. When groups exceed fills, emit a `cli::cli_warn()` with the fix. Uses the same `vec_unique`/`vec_group_id`/`tabulate` pattern already at lines 63-65 of the function.

Does not fire when: the user has already set `group = <fill_var>`, only `fill` is mapped, `fill` is absent, or `fill` is continuous.

**Documentation** (`R/position-jitterdodge.R`): New `@section Interaction with grouping:` explains the mechanism and the `aes(group = ...)` fix. New `\donttest{}` example demonstrates the pitfall and solution using a small data frame.

**Tests** (`tests/testthat/test-position-jitterdodge.R`): 4 new tests covering warning/no-warning scenarios.

**NEWS** (`NEWS.md`): Entry added.

## Checklist

- [x] Motivation described above and in NEWS entry (`@Jesssullivan, #XXXX`)
- [x] Only related changes (warning + docs for this single issue)
- [x] Tidyverse style — follows existing `cli::cli_warn()` patterns in position code
- [x] roxygen2 docs updated, `devtools::document()` run
- [x] Unit tests added (4 new, all passing)
- [ ] Visual tests — N/A (not a graphical output change)
- [x] Minimal example added to `@examples`
