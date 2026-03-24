## ------------------------------------------------------------------------
##
## Purpose: Import data and source scripts
## Author: Yanwen Wang
## Date Created: 2024-10-06
## Email: yanwen.wang@nyu.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Load the required packages
using Arrow
using CategoricalArrays
using DataFrames
using DataFramesMeta
using Distributions
using FreqTables
using GLM
using LinearAlgebra
using ProportionalFitting
using Random
using RCall
using Shapefile
using StatsBase

R"library(tidyverse)"
R"library(MatchIt)"

# Load dictionaries and functions
include("../scripts_tidy/dictionaries.jl")
include("../scripts_analysis/functions.jl")

# Create output directories
mkpath("data/visualization")

# Load data
census = DataFrame(Arrow.Table("data/processed/census.arrow"))
sample = DataFrame(Arrow.Table("data/processed/sample.arrow"))
