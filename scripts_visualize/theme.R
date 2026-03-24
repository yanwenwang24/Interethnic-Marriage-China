## ------------------------------------------------------------------------
##
## Purpose: Shared ggplot2 theme and color palettes
## Author: Yanwen Wang
## Date Created: 2026-03-24
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------

library(ggplot2)

# --- Custom theme ---------------------------------------------------------

theme_intermarriage <- function(base_size = 11, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    theme(
      # Panel
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
      panel.border       = element_blank(),
      panel.spacing      = unit(1, "lines"),

      # Axes
      axis.line.x    = element_line(color = "grey40", linewidth = 0.4),
      axis.ticks.x   = element_line(color = "grey40", linewidth = 0.3),
      axis.ticks.length = unit(0.15, "cm"),
      axis.title     = element_text(size = rel(0.95), color = "grey20"),
      axis.text      = element_text(size = rel(0.85), color = "grey30"),
      axis.text.x    = element_text(margin = margin(t = 3)),

      # Strip (facet labels)
      strip.text = element_text(
        size = rel(0.9), face = "bold", color = "grey20",
        margin = margin(b = 4, t = 4)
      ),
      strip.background = element_blank(),

      # Legend
      legend.position  = "bottom",
      legend.title     = element_text(size = rel(0.85), face = "bold"),
      legend.text      = element_text(size = rel(0.8)),
      legend.key.size  = unit(0.9, "lines"),
      legend.margin    = margin(t = 4),

      # Plot
      plot.title    = element_text(size = rel(1.1), face = "bold", hjust = 0),
      plot.subtitle = element_text(size = rel(0.9), color = "grey40", hjust = 0),
      plot.margin   = margin(10, 10, 10, 10)
    )
}

# --- Color palettes -------------------------------------------------------

# Gender (Figure 1)
pal_gender <- c("female" = "#b3bfd1", "male" = "#b04238")

# Education 3-level (Figures 2, 3)
pal_edu_3 <- c("Low" = "#d7e1ee", "Middle" = "#a4a2a8", "High" = "#991f17")

# Year (Figures 4, 5)
pal_year <- c(
  "1982" = "#cbd6e4", "1990" = "#b3bfd1",
  "2000" = "#df8879", "2010" = "#b04238"
)

# Education pairing 5-level (Figures 6, 7)
pal_edu_5 <- c(
  "homo1"  = "#d7e1ee", "homo2" = "#bfcbdb",
  "homo3"  = "#a4a2a8", "heter1" = "#c86558",
  "heter2" = "#991f17"
)

# --- Label maps -----------------------------------------------------------

gender_labels <- c("female" = "Female", "male" = "Male")

edu_5_labels <- c(
  "homo1"  = "Homo. (Low)",
  "homo2"  = "Homo. (Mid.)",
  "homo3"  = "Homo. (High)",
  "heter1" = "Hetero. (1)",
  "heter2" = "Hetero. (2)"
)

# --- Factor orderings -----------------------------------------------------

ethngrp_order <- c(
  "Han", "Hui", "Kazakh", "Korean",
  "Manchu", "Mongolian", "Southern", "Tibetan", "Uyghur"
)

ethngrp_order_minority <- setdiff(ethngrp_order, "Han")

region_order <- c(
  "North", "Northeast", "East",
  "South Central", "Southwest", "Northwest"
)

year_order <- c("1982", "1990", "2000", "2010")

edu_3_order <- c("Low", "Middle", "High")

edu_5_order <- c("homo1", "homo2", "homo3", "heter1", "heter2")
