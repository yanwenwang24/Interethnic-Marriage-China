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
using AlgebraOfGraphics
using Arrow
using CairoMakie
using CategoricalArrays
using DataFrames
using DataFramesMeta
using FreqTables
using GLM
using MakieThemes
using ProportionalFitting
using Random
using RCall
using Shapefile
using StatsBase

R"library(tidyverse)"
R"library(MatchIt)"

set_theme!(theme_ggthemr(:fresh))

# Load dictionaries and functions
include("../scripts_tidy/dictionaries.jl")
include("functions.jl")

# Load data
census = DataFrame(Arrow.Table("Data_cleaned/census.arrow"))
sample = DataFrame(Arrow.Table("Data_cleaned/sample.arrow"))