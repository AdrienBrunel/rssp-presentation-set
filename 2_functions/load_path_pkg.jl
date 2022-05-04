# ==============================================================================
#  LOAD JULIA LIBRARIES
# ==============================================================================
    import Pkg
    using Printf;
    using DataFrames;
    using DelimitedFiles;
    using CSV;
    using JuMP;
    using Cbc;
    using Gurobi
    using Plots;
    using GR;
    using NetCDF;
    using LinearAlgebra;
    using Distributions


# ==============================================================================
#  PATH MANAGEMENT
# ==============================================================================
    data_dir   = "$(root_dir)/1_data";
    func_dir   = "$(root_dir)/2_functions";
    res_dir    = "$(root_dir)/3_results";
    report_dir = "$(root_dir)/4_report";
    sc_dir_0   = "$(res_dir)/$(folder)";
    pic_dir_0  = "$(report_dir)/pictures/$(folder)";
    sc_dir     = "$sc_dir_0/$(type)";
    pic_dir    = "$pic_dir_0/$(type)";

    for d in [sc_dir_0;pic_dir_0;sc_dir;pic_dir]
        if !isdir(d)
            mkdir(d);
            println("Creation of folder $(d)")
        end
    end

    if !isdir("$(data_dir)/$(folder)")
        println("WARNING! Folder $(folder) with input data is missing")
    end
