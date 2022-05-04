root_dir=pwd();
# ==============================================================================
# 1 - PARAMETERS
# ==============================================================================
	# High level
	opti    = true
	visu    = true
	folder  = "sc_40x25pu_5cf"

	# Instance
	beta    = 2
	targets = 0.25 .* [1,1,1,1,1]

	# Presentation set
	gap   = 0.10
	N_sol = 5
	dpu   = 45
	type  = "max_pdist"


# ==============================================================================
# 2 - LOAD INSTANCE
# ==============================================================================
	# Load libraries, functions, data structure and models
	println("load_path_pkg.jl  ...");include("$(root_dir)/2_functions/load_path_pkg.jl");
	println("load_functions.jl ...");include("$(func_dir)/load_functions.jl");
	println("load_struct.jl    ...");include("$(func_dir)/load_struct.jl");
	println("load_model.jl     ...");include("$(func_dir)/load_model.jl");

    t1 = time_ns()

	# Indicate input data files
    pu_fname     = "$(data_dir)/$(folder)/pu.csv"
    cf_fname     = "$(data_dir)/$(folder)/cf.csv"
    bound_fname  = "$(data_dir)/$(folder)/bound.csv"
    coords_fname = "$(data_dir)/$(folder)/coords.csv"

    # Create instance and regular grid
    gridgraph = RegularGrid(coords_fname)
    instance  = Instance(pu_fname,cf_fname,bound_fname,beta,targets,gridgraph)

	t2 = time_ns()
	loading_time = round((t2-t1)/1e9,digits=2)
    println("Instance of nominal problem created ($(loading_time)s)")


# ==============================================================================
# 3 - BUILD THE PRESENTATION SET
# ==============================================================================
	if opti == true

	    t1 = time_ns()

		# Build the presentation set
		if type == "max_pdist"
			X,m = presentation_set_max_pdistance(instance,gridgraph,N_sol,gap)
		elseif type == "con_pdist"
			X,m = presentation_set_con_pdistance(instance,gridgraph,N_sol,dpu)
		else
			println("WARNING! Variable type $(type) is not recognized")
		end

		t2 = time_ns()
		computation_time = round((t2-t1)/1e9,digits=2)
	    println("Portfolio of alternative solutions built ($(computation_time)s)")

		for k in 1:size(X)[2]
			# Create a reserve object with k alternatives
			reserve  = Reserve(X[:,k],instance)

			# Write reserve solutions in a .csv file
			sol_fname = "$(sc_dir)/sol_alt_$(beta)_$(targets[1])_$(k-1).csv"
	        sol_data  = DataFrame([instance.PlanningUnits reserve.x])
	        rename!(sol_data,["id","reserve"])
	        CSV.write(sol_fname, sol_data, writeheader=true)
		end
	end


# ==============================================================================
# 4 - VISUALISATION
# ==============================================================================
	if visu == true
	    t1 = time_ns()
	    plot_opt = PlotOptions(gridgraph.N_x*30,gridgraph.N_y*30,"Longitude [deg]","Latitude [deg]",5)
		for k in 1:N_sol
			sol_fname = "$(sc_dir)/sol_alt_$(beta)_$(targets[1])_$(k-1).csv"
			sol_data = CSV.read(sol_fname, header=1, delim=",")
	        reserve  = Reserve(sol_data.reserve,instance)
			visualisation_output(reserve,instance,gridgraph,plot_opt,"sol_alt_$(beta)_$(targets[1])_$(k-1).png")
		end
	    t2 = time_ns()
		visualisation_time = round((t2-t1)/1e9,digits=2)
	    println("Visualisation over ($(visualisation_time)s)")
	end
