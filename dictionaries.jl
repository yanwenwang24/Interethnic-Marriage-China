## ------------------------------------------------------------------------
##
## Script name: dictionaries.jl
## Purpose: Define dictionaries for data cleaning
## Author: Yanwen Wang
## Date Created: 2024-10-04
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Ethnicity -------------------------------------------------------------

# Ethnicity
ethn_dict = Dict(
    1 => "汉族", 2 => "蒙古族", 3 => "回族", 4 => "藏族", 5 => "维吾尔族",
    6 => "苗族", 7 => "彝族", 8 => "壮族", 9 => "布依族", 10 => "朝鲜族",
    11 => "满族", 12 => "侗族", 13 => "瑶族", 14 => "白族", 15 => "土家族",
    16 => "哈尼族", 17 => "哈萨克族", 18 => "傣族", 19 => "黎族", 20 => "傈僳族",
    21 => "佤族", 22 => "畲族", 23 => "高山族", 24 => "拉祜族", 25 => "水族",
    26 => "东乡族", 27 => "纳西族", 28 => "景颇族", 29 => "柯尔克孜族", 30 => "土族",
    31 => "达斡尔族", 32 => "仫佬族", 33 => "羌族", 34 => "布朗族", 35 => "撒拉族",
    36 => "毛南族", 37 => "仡佬族", 38 => "锡伯族", 39 => "阿昌族", 40 => "普米族",
    41 => "塔吉克族", 42 => "怒族", 43 => "乌兹别克族", 44 => "俄罗斯族", 45 => "鄂温克族",
    46 => "德昂族", 47 => "保安族", 48 => "裕固族", 49 => "京族", 50 => "塔塔尔族",
    51 => "独龙族", 52 => "鄂伦春族", 53 => "赫哲族", 54 => "门巴族", 55 => "珞巴族",
    56 => "基诺族"
)

# Ethnic groups
ethngrp_dict1 = Dict(
    1 => "Han",
    2 => "Mongolian",
    3 => "Hui",
    4 => "Tibetan",
    5 => "Uyghur",
    6 => "Southern",
    7 => "Southern",
    8 => "Southern",
    9 => "Southern",
    10 => "Korean",
    11 => "Manchu",
    12 => "Southern",
    13 => "Southern",
    14 => "Southern",
    15 => "Southern",
    16 => "Southern",
    17 => "Kazakh",
    18 => "Southern",
    19 => "Southern",
    20 => "Southern",
    21 => "Southern",
    22 => "Southern",
    23 => "Southern",
    24 => "Southern",
    25 => "Southern",
    26 => "Hui",
    27 => "Southern",
    28 => "Southern",
    29 => "Kazakh",
    30 => "Tibetan",
    31 => "Mongolian",
    32 => "Southern",
    33 => "Southern",
    34 => "Southern",
    35 => "Hui",
    36 => "Southern",
    37 => "Southern",
    38 => "Manchu",
    39 => "Southern",
    40 => "Southern",
    41 => "Kazakh",
    42 => "Southern",
    43 => "Kazakh",
    44 => "Kazakh",
    45 => "Mongolian",
    46 => "Southern",
    47 => "Hui",
    48 => "Tibetan",
    49 => "Southern",
    50 => "Kazakh",
    51 => "Southern",
    52 => "Mongolian",
    53 => "Manchu",
    54 => "Tibetan",
    55 => "Tibetan",
    56 => "Southern"
)

ethngrp_dict2 = Dict(
    # Han
    "汉族" => "Han",
    # Tibetan
    "藏族" => "Tibetan",
    "裕固族" => "Tibetan",
    "门巴族" => "Tibetan",
    "珞巴族" => "Tibetan",
    "土族" => "Tibetan",
    # Hui
    "回族" => "Hui",
    "撒拉族" => "Hui",
    "东乡族" => "Hui",
    "保安族" => "Hui",
    # Manchu
    "满族" => "Manchu",
    "赫哲族" => "Manchu",
    "锡伯族" => "Manchu",
    # Mongolian
    "蒙古族" => "Mongolian",
    "鄂伦春族" => "Mongolian",
    "鄂温克族" => "Mongolian",
    "达斡尔族" => "Mongolian",
    # Kazakh
    "哈萨克族" => "Kazakh",
    "乌兹别克族" => "Kazakh",
    "塔吉克族" => "Kazakh",
    "柯尔克孜族" => "Kazakh",
    "塔塔尔族" => "Kazakh",
    "俄罗斯族" => "Kazakh",
    # Korean
    "朝鲜族" => "Korean",
    # Uyghur
    "维吾尔族" => "Uyghur",
    # Southern (the rest of the ethnicities)
    "苗族" => "Southern",
    "彝族" => "Southern",
    "壮族" => "Southern",
    "布依族" => "Southern",
    "侗族" => "Southern",
    "瑶族" => "Southern",
    "白族" => "Southern",
    "土家族" => "Southern",
    "哈尼族" => "Southern",
    "傣族" => "Southern",
    "黎族" => "Southern",
    "傈僳族" => "Southern",
    "佤族" => "Southern",
    "畲族" => "Southern",
    "高山族" => "Southern",
    "拉祜族" => "Southern",
    "水族" => "Southern",
    "纳西族" => "Southern",
    "景颇族" => "Southern",
    "仫佬族" => "Southern",
    "羌族" => "Southern",
    "布朗族" => "Southern",
    "毛南族" => "Southern",
    "仡佬族" => "Southern",
    "阿昌族" => "Southern",
    "普米族" => "Southern",
    "怒族" => "Southern",
    "德昂族" => "Southern",
    "京族" => "Southern",
    "独龙族" => "Southern",
    "基诺族" => "Southern"
)

# 2 Marital status -------------------------------------------------------------

marst_dict = Dict(
    1 => "never-married",
    2 => "married",
    3 => "divorced",
    4 => "widowed"
)

# 3 Education -------------------------------------------------------------------

# Census 1982, 1990, 2000
eduraw_map = Vector{Union{Missing,Int}}(undef, 100)
fill!(eduraw_map, missing)
for i in 0:99
    if i == 0
        eduraw_map[i+1] = 1
    elseif 10 <= i && i < 20
        eduraw_map[i+1] = 2
    elseif 20 <= i && i < 30
        eduraw_map[i+1] = 3
    elseif 30 <= i && i < 40
        eduraw_map[i+1] = 4
    elseif 40 <= i && i < 50
        eduraw_map[i+1] = 5
    elseif 50 <= i && i < 80
        eduraw_map[i+1] = 6
    end
end

edu_map = Vector{Union{Missing,Int}}(undef, 100)
fill!(edu_map, missing)
for i in 0:99
    if i < 20
        edu_map[i+1] = 1
    elseif 20 <= i && i < 30
        edu_map[i+1] = 2
    elseif 30 <= i && i < 80
        edu_map[i+1] = 3
    end
end

# Census 2010
eduraw_2010_dict = Dict(
    1 => 1,
    2 => 2,
    3 => 3,
    4 => 4,
    5 => 5,
    6 => 6,
    7 => 6
)

edu_2010_dict = Dict(
    1 => 1,
    2 => 1,
    3 => 2,
    4 => 3,
    5 => 3,
    6 => 3,
    7 => 3
)