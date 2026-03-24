## ------------------------------------------------------------------------
##
## Purpose: Log-linear model coefficients by ethnic group (regional)
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig5_odds_by_ethngrp_region.arrow") |>
  mutate(
    ethngrp = factor(ethngrp, levels = ethngrp_order_minority),
    year = factor(year, levels = year_order),
    region = factor(region, levels = region_order)
  )

pd <- position_dodge(width = 0.6)

p <- ggplot(df, aes(x = ethngrp, y = coefficient, color = year)) +
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
  scale_color_manual(values = pal_year, name = "Year") +
  scale_y_continuous(breaks = seq(-12, 2, 2), limits = c(-12, 1)) +
  labs(x = NULL, y = "Coefficient (Log Scale)") +
  theme_intermarriage() +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 30, hjust = 1, size = rel(0.75))
  )

ggsave("figures/odds_by_ethngrp_region.pdf", p,
       width = 6.5, height = 8, device = cairo_pdf)

message("  Figure 5: odds_by_ethngrp_region.pdf")
