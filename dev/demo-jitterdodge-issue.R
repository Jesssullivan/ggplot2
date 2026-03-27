# Demo: position_jitterdodge() grouping misalignment
# ===================================================
#
# This script demonstrates the silent misalignment that occurs when
# overlaying jittered points on dodged boxplots with additional discrete
# aesthetics. Uses only base R datasets (mtcars).
#
# Run with: source("dev/demo-jitterdodge-issue.R")

library(ggplot2)

# --- Setup: prepare mtcars with clear categorical + logical variables ---
df <- within(mtcars, {
  cyl  <- factor(cyl)             # 3 levels: 4, 6, 8
  am   <- factor(am, labels = c("auto", "manual"))  # transmission
  high_mpg <- mpg > median(mpg)   # logical: above/below median
})

# =====================================================================
# SCENARIO 1: Works perfectly
# Only fill mapped -> implicit group = cyl x am -> matches boxplot
# =====================================================================
p1 <- ggplot(df, aes(x = cyl, y = mpg, fill = am)) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(
    position = position_jitterdodge(jitter.width = 0.15, seed = 42)
  ) +
  labs(
    title = "Scenario 1: fill only — points align correctly",
    subtitle = "Implicit group = cyl x am (matches boxplot)"
  )

# =====================================================================
# SCENARIO 2: Breaks silently (CURRENT BEHAVIOR)
# colour = high_mpg added -> implicit group = cyl x am x high_mpg
# Boxplot still groups by cyl x am -> mismatch -> misaligned points
# =====================================================================
p2 <- ggplot(df, aes(x = cyl, y = mpg, fill = am)) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(
    aes(colour = high_mpg),
    position = position_jitterdodge(jitter.width = 0.15, seed = 42)
  ) +
  labs(
    title = "Scenario 2: fill + colour — points MISALIGN (current bug)",
    subtitle = "Implicit group = cyl x am x high_mpg (inflated beyond boxplot)"
  )

# =====================================================================
# SCENARIO 3: Manual workaround (CURRENT FIX)
# Explicit group = am overrides implicit grouping
# =====================================================================
p3 <- ggplot(df, aes(x = cyl, y = mpg, fill = am)) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(
    aes(colour = high_mpg, group = am),
    position = position_jitterdodge(jitter.width = 0.15, seed = 42)
  ) +
  labs(
    title = "Scenario 3: explicit group = am — points align (workaround)",
    subtitle = "User must know to set group to the fill variable"
  )

# =====================================================================
# AFTER BRANCH 2 (jitterdodge-smart-default):
# Scenario 2 would produce the same result as Scenario 3 automatically,
# because position_jitterdodge() infers dodge grouping from fill.
# =====================================================================

# --- Print all three ---
print(p1)
print(p2)
print(p3)

cat("\n")
cat("Scenario 1: fill only        -> correct alignment\n")
cat("Scenario 2: fill + colour    -> MISALIGNED (current behavior)\n")
cat("Scenario 3: fill + colour    -> correct (manual group= workaround)\n")
cat("\n")
cat("Branch 1 (docs-warning): Scenario 2 would emit a warning guiding\n")
cat("  the user to apply the Scenario 3 fix.\n")
cat("Branch 2 (smart-default): Scenario 2 would just work — no\n")
cat("  workaround needed.\n")
