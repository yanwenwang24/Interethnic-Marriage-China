## ------------------------------------------------------------------------
##
## Purpose: Log-linear model coefficients by education pairing (national)
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig6_odds_by_edu.arrow") |>
  filter(!ethngrp %in% c("Kazakh", "Uyghur")) |>
  mutate(
    ethngrp = factor(ethngrp, levels = ethngrp_order_minority),
    edu = factor(edu, levels = edu_5_order)
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
    size = 0.3, stroke = 1.0
  ) +
  scale_color_manual(
    values = pal_edu_5,
    name = "Edu. Pairing",
    labels = edu_5_labels
  ) +
  scale_y_continuous(breaks = seq(-10, 2, 2), limits = c(-9, 1)) +
  labs(x = NULL, y = "Coefficient (Log Scale)") +
  theme_intermarriage() +
  theme(legend.position = "right")

ggsave("figures/odds_by_edu.pdf", p,
       width = 6.5, height = 5, device = cairo_pdf)

message("  Figure 6: odds_by_edu.pdf")
