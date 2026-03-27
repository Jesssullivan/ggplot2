Infer dodge grouping from `fill` in `position_jitterdodge()`

Closes #XXXX.

## Motivation

`position_jitterdodge()` is documented as "primarily used for aligning points generated through `geom_point()` with dodged boxplots (e.g., a `geom_boxplot()` with a fill aesthetic supplied)." However, the function currently derives dodge grouping from the full implicit `group` interaction, which includes every discrete aesthetic in the layer — not just `fill`. Adding `colour`, `shape`, or `linetype` silently breaks the alignment this function is designed to provide.

```r
# Points misalign because group = cyl x am x vs, but boxplot dodges by cyl x am
ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs)),
             position = position_jitterdodge(seed = 1))
```

## Approach

Since this function exists specifically for boxplot+point alignment, and boxplots dodge by `fill`, the dodge grouping should derive from `fill` when available.

A 6-line unexported helper (`jitterdodge_dodge_group`) checks whether `fill` is present and discrete, returning either a fill-based group or falling back to the standard `group`. Three methods (`setup_params`, `setup_data`, `compute_panel`) use this helper to temporarily swap the group for dodging, then restore the original group for downstream use. No new parameters are added.

## Note on existing behaviour

We understand that ggplot2 is a mature package and that PRs changing existing behaviour require careful consideration. This change only affects the case where the current output is visually incorrect:

| Scenario | Before | After | Change? |
|----------|--------|-------|---------|
| `fill` only | Dodge by fill | Dodge by fill | Identical |
| `fill` + `colour` | Dodge by fill x colour | Dodge by fill | **Fix** |
| No `fill` | Dodge by group | Dodge by group | Identical |
| Continuous `fill` | Dodge by group | Dodge by group | Identical |

The only behaviour change is in the case where the current result contradicts the function's documented purpose. Users who need the old grouping can use `aes(group = interaction(fill, colour))` explicitly.

## Changes

- `R/position-jitterdodge.R`: `jitterdodge_dodge_group()` helper + modifications to `setup_params`, `setup_data`, `compute_panel`
- `R/position-jitterdodge.R`: New `@section Dodge grouping:` documenting the inference and fallback
- `tests/testthat/test-position-jitterdodge.R`: 5 new tests (alignment, backward compat, no-fill fallback, continuous-fill fallback, existing preserve tests still pass)
- `NEWS.md`: Entry added

## Checklist

- [x] Motivation described above and in NEWS entry (`@Jesssullivan, #XXXX`)
- [x] Only related changes (single concern: fill-based dodge inference)
- [x] Tidyverse style — follows existing patterns, reuses `id()`, `is_discrete()`
- [x] roxygen2 docs updated, `devtools::document()` run
- [x] Unit tests added (5 new, all passing; 22 position-dodge regression tests also pass)
- [ ] Visual tests — N/A
- [x] Minimal example added to `@examples`
