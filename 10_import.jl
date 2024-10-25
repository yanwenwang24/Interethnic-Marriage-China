## ------------------------------------------------------------------------
##
## Script name: 10_import.jl
## Purpose: Import data and source scripts
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Load the required packages
using DataFrames, DataFramesMeta, CategoricalArrays
using Arrow, Shapefile
using StatsBase, Random, FreqTables, ProportionalFitting, GLM
using AlgebraOfGraphics, CairoMakie, MakieThemes
using RCall

R"library(tidyverse)"
R"library(MatchIt)"

set_theme!(theme_ggthemr(:fresh))

# Load functions
include("functions.jl")

# Load data
census = DataFrame(Arrow.Table("Data_cleaned/census.arrow"))
sample = DataFrame(Arrow.Table("Data_cleaned/sample.arrow"))