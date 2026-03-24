## ------------------------------------------------------------------------
##
## Purpose: Intermarriage trends by ethnic group
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

df <- read_feather("data/visualization/fig1_trends_by_ethngrp.arrow") |>
  mutate(ethngrp = factor(ethngrp, levels = ethngrp_order))

arrange(df, ethngrp, year) %>%
  mutate(prop = sprintf("%.2f", prop * 100)) %>%
  print(n = Inf)

p <- ggplot(df, aes(x = year, y = prop)) +
  geom_line(linewidth = 0.7, color = "grey30") +
  geom_point(size = 2, color = "grey30") +
  facet_wrap(~ethngrp, nrow = 3) +
  scale_x_continuous(breaks = as.numeric(year_order)) +
  scale_y_continuous(
    labels = percent_format(),
    breaks = seq(0, 0.8, 0.2),
    limits = c(0, NA)
  ) +
  labs(x = NULL, y = "Proportion of Intermarriage") +
  theme_intermarriage()

ggsave("figures/trends_by_ethngrp.pdf", p,
  width = 6.5, height = 6, device = cairo_pdf
)

message("  Figure 1: trends_by_ethngrp.pdf")
