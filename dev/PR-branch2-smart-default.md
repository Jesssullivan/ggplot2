# PR: Infer dodge grouping from `fill` in `position_jitterdodge()`

## Problem

Same root cause as the docs/warning PR: `position_jitterdodge()` relies on the
implicit `group` aesthetic for dodge alignment, but `add_group()` computes
groups from *all* discrete aesthetics. Mapping `colour`, `shape`, or `linetype`
in the point layer inflates groups beyond what the boxplot uses, causing silent
misalignment.

```r
# mtcars: points scatter across wrong dodge slots
ggplot(mtcars, aes(factor(cyl), mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = mpg > 20),
             position = position_jitterdodge())
```

## What this PR does

`position_jitterdodge()` is documented as "primarily used for aligning points
with dodged boxplots (e.g., a `geom_boxplot()` with a fill aesthetic
supplied)." Since boxplots dodge by `fill`, the dodge grouping should derive
from `fill` — not the full group interaction.

**One helper function, three call sites:**

```r
# 6-line unexported helper
jitterdodge_dodge_group <- function(data) {
  if ("fill" %in% names(data) && is_discrete(data[["fill"]])) {
    return(id(data["fill"], drop = TRUE))
  }
  data$group
}
```

The three methods (`setup_params`, `setup_data`, `compute_panel`) each
swap `data$group` with the fill-derived group before delegating to the
existing dodge machinery, then restore the original group afterward.
The existing `collide()`/`pos_dodge()` code is untouched.

## Backward compatibility

| Scenario | Before | After | Change? |
|----------|--------|-------|---------|
| `fill` only | Dodge by fill (via group) | Dodge by fill | Identical |
| `fill` + `colour` | Dodge by fill x colour | Dodge by fill | **Fix** |
| No `fill` | Dodge by group | Dodge by group | Identical |
| Continuous `fill` | Dodge by group | Dodge by group | Identical |

The only behavior change is in the broken case — where the current behavior
produces visually incorrect output that users report as a bug.

## Why not a new parameter?

A `dodge.by` parameter was considered but rejected:

- It adds API surface to solve what should be a sensible default
- The function's documented purpose is boxplot+point alignment — the default
  should serve that use case without configuration
- Users who need exotic dodge grouping can still use `aes(group = ...)`

## Testing

5 new tests:
- Points align with boxplot when extra colour is present (core fix)
- Unchanged when fill is only discrete aesthetic (backward compat)
- Falls back to group when no fill
- Continuous fill falls back to group
- Existing preserve tests still pass

## Rationale

- **Zero API change** — no new parameters, constructor untouched
- **~15 lines of logic** — one helper + three swap/restore blocks
- **Reuses existing infrastructure** — `id()`, `is_discrete()`, `collide()`, `pos_dodge()`
- **Self-documenting** — the function's stated purpose ("aligning points with
  dodged boxplots") now matches its actual behavior
