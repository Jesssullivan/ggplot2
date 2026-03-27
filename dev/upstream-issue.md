`position_jitterdodge()` silently misaligns points when additional discrete aesthetics are mapped.

When overlaying jittered points on dodged boxplots, adding a discrete aesthetic like `colour` to the point layer causes the points to land in incorrect dodge positions. No warning is emitted.

```r
library(ggplot2)

# Works: fill only
ggplot(mtcars, aes(x = factor(cyl), y = mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(position = position_jitterdodge(seed = 1))

# Misaligned: adding colour = factor(vs) to the point layer
ggplot(mtcars, aes(x = factor(cyl), y = mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs)),
             position = position_jitterdodge(seed = 1))

# Workaround: explicitly set group to match the fill variable
ggplot(mtcars, aes(x = factor(cyl), y = mpg, fill = factor(am))) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs), group = factor(am)),
             position = position_jitterdodge(seed = 1))
```

In the second plot, points are distributed across incorrect horizontal positions because the implicit `group` aesthetic becomes `cyl x am x vs` (the interaction of all discrete aesthetics), while the boxplot dodges by `cyl x am` only. The dodge machinery then divides the available width across more groups than the boxplots have, causing misalignment.

The workaround is `aes(group = factor(am))`, which overrides the implicit grouping to match the boxplot's fill-based dodge. However, this requires understanding how ggplot2 computes implicit groups from discrete aesthetics, which is non-obvious even for experienced users.

This pattern comes up frequently when users want to colour points by a secondary variable (e.g., a status flag or subgroup) while keeping them aligned with their respective boxplots.
