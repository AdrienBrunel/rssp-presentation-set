# ==============================================================================
#  OPTIMISATION EXECUTION
# ==============================================================================

    ## Computation -------------------------------------------------------------
        optimize!(RSSP);


    ## Results -----------------------------------------------------------------
        x_opt = value.(RSSP[:x]).data
        z_opt = value.(RSSP[:z]).data
        x_opt,z_opt = read_reserve_solution(RSSP,gridgraph)
        ReserveSize, ReservePerimetre,ReserveCout,ReserveScore = print_reserve_solution(x_opt,z_opt,instance,gridgraph)


    ## Generation --------------------------------------------------------------
        sol_fname = string(sc_dir,"/solution.csv")
        sol_data  = DataFrame([instance.PlanningUnits x_opt])
        rename!(sol_data,["id","reserve"])
        CSV.write(sol_fname, sol_data, writeheader=true)
