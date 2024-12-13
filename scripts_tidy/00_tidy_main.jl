## ------------------------------------------------------------------------
##
## Script name: 00_tidy_master.jl
## Purpose: Master file to tidy the raw data
## Author: Yanwen Wang
## Date Created: 2024-10-04
## Email: yanwenwang@u.nus.edu
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
using FreqTables
using StatsBase

# Load dictionaries and functions
include("dictionaries.jl")
include("functions.jl")

# Source scripts
@time include("01_tidy_82.jl")
@time include("02_tidy_90.jl")
@time include("03_tidy_00.jl")
@time include("04_tidy_10.jl")
@time include("05_tidy_join.jl")