# Minimal demo: 3 plots, copy-paste into R console
# Uses only mtcars — no data prep needed.

library(ggplot2)

# Shared base: boxplots of mpg by cylinder count, dodged by transmission
base <- ggplot(mtcars, aes(x = factor(cyl), y = mpg, fill = factor(am)))

# 1. WORKS: fill only
base +
  geom_boxplot(outlier.shape = NA) +
  geom_point(position = position_jitterdodge(seed = 1)) +
  ggtitle("Works: fill only")

# 2. BREAKS: adding colour = factor(vs) inflates implicit groups
base +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs)),
             position = position_jitterdodge(seed = 1)) +
  ggtitle("Breaks: colour inflates groups")

# 3. WORKAROUND: explicit group = factor(am)
base +
  geom_boxplot(outlier.shape = NA) +
  geom_point(aes(colour = factor(vs), group = factor(am)),
             position = position_jitterdodge(seed = 1)) +
  ggtitle("Fix: explicit group = am")
