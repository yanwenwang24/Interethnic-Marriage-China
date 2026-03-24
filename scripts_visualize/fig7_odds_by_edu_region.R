## ------------------------------------------------------------------------
##
## Purpose: Log-linear model coefficients by education pairing (regional)
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig7_odds_by_edu_region.arrow") |>
  mutate(
    ethngrp = factor(ethngrp, levels = ethngrp_order_minority),
    edu = factor(edu, levels = edu_5_order),
    region = factor(region, levels = region_order)
  )

pd <- position_dodge(width = 0.7)

p <- ggplot(df, aes(x = ethngrp, y = coefficient, color = edu)) +
  geom_hline(
    yintercept = 0, linetype = "dashed",
    color = "grey50", linewidth = 0.4
  ) +
  geom_pointrange(
    aes(ymin = coefficient - std_bar, ymax = coefficient + std_bar),
    position = pd, shape = 21, fill = "white",
    size = 0.25, stroke = 0.8
  ) +
  facet_wrap(~ region, ncol = 2, scales = "free_x") +
  scale_color_manual(
    values = pal_edu_5,
    name = "Edu. Pairing",
    labels = edu_5_labels
  ) +
  scale_y_continuous(breaks = seq(-8, 2, 2), limits = c(-7, 1)) +
  labs(x = NULL, y = "Coefficient (Log Scale)") +
  theme_intermarriage() +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 30, hjust = 1, size = rel(0.75))
  )

ggsave("figures/odds_by_edu_region.pdf", p,
       width = 6.5, height = 8, device = cairo_pdf)

message("  Figure 7: odds_by_edu_region.pdf")
