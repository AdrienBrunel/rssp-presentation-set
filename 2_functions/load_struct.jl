# ==============================================================================
#  GRID
# ==============================================================================
    struct RegularGrid
        N_x::Int64
        N_y::Int64
        N_pu::Int64
        xloc::Array{Float64,1}
        yloc::Array{Float64,1}
        Noeuds::Vector{Int}
        Aretes::Vector{Pair{Int,Int}}
        Voisins::Vector{Vector{Int}}
        Arcs::Vector{Pair{Int,Int}}
        NoeudsPeripheriques::Vector{Int}
        lon_seq::Array{Float64,1}
        lat_seq::Array{Float64,1}


        # grid data initialisation
        function RegularGrid(coords_fname)

            # Check if the input data files exist
            if !isfile(coords_fname)
                println("WARNING! File $(f) is missing")
            end

            # Read input files
            coords_data = CSV.read(coords_fname, header=1, delim=",")

            # Derive information from coordinates
            N_x = sum(coords_data.yloc .== minimum(coords_data.yloc))
        	N_y = sum(coords_data.xloc .== minimum(coords_data.xloc))
        	blpu_lon = minimum(coords_data.xloc)
        	blpu_lat = minimum(coords_data.yloc)
        	lon_res = unique(coords_data.xloc)[2]-unique(coords_data.xloc)[1]
        	lat_res = unique(coords_data.yloc)[2]-unique(coords_data.yloc)[1]

            # Longitude/Latitude grid info
            lon_seq = collect(blpu_lon:lon_res:maximum(coords_data.xloc))
            lat_seq = collect(blpu_lat:lat_res:maximum(coords_data.yloc))

            # Grid size
            N_pu = N_x*N_y
            Noeuds = collect(1:N_pu)

            # Planning units coordinates
            xloc = Array{Float64,1}(undef,N_pu)
            yloc = Array{Float64,1}(undef,N_pu)
            for k in 1:N_pu

                # planning unit location
                xloc[k] = coords_data.xloc[k]
                yloc[k] = coords_data.yloc[k]

            end

            # Neighbours initialisation
            Voisins = Vector{Vector{Int}}()
            for k in Noeuds
                push!(Voisins, Vector{Int}())
            end

            Aretes = Vector{Pair{Int,Int}}()
            for k in Noeuds
                # arêtes horizontales
                if mod(k,N_x) != 0
                    push!(Aretes,(k=>k+1))
                    push!(Voisins[k], k+1)
                    push!(Voisins[k+1], k)
                end
                # arêtes verticales
                if k <= (N_y-1)*N_x
                    push!(Aretes,(k=>k+N_x))
                    push!(Voisins[k], k+N_x)
                    push!(Voisins[k+N_x], k)
                end
            end

            # Arcs du graphe associé à la grille de taille Nx*Ny
            Arcs = Vector{Pair{Int,Int}}()
            for a in Aretes
                push!(Arcs,a[1]=>a[2])
                push!(Arcs,a[2]=>a[1])
            end

            # Noeuds périphériques du graphe
            NoeudsPeripheriques = Vector{Int64}()
            for k in Noeuds
                if length(Voisins[k]) < 4
                    push!(NoeudsPeripheriques,k)
                end
            end

            # Constructor
            new(N_x,N_y,N_pu,xloc,yloc,Noeuds,Aretes,Voisins,Arcs,NoeudsPeripheriques,lon_seq,lat_seq)

        end

    end

# ==============================================================================
#  INSTANCE
# ==============================================================================
    struct Instance
        N_pu::Int64
        N_cf::Int64
        N_bd::Int64
        PlanningUnits::Array{Int64,1}
        ConservationFeatures::Array{Int64,1}
        Cost::Array{Float64,2}
        IsLockedOut::Array{Int8,2}
        LockedOut::Vector{Int64}
        Amount::Array{Float64,2}
        Targets::Array{Float64,2}
        BoundaryLength::Dict{Pair{Int,Int},Int}
        BoundaryCorrection::Array{Float64,2}
        Beta::Float64


        # input data initialisation
        function Instance(pu_fname,cf_fname,bound_fname,beta,targets,gridgraph)

            # Check if the input data files exist
            for f in [pu_fname,cf_fname,bound_fname]
                if !isfile(f)
                    println("WARNING! File $(f) is missing")
                end
            end

            # Data of the graph associated with the grid
            Voisins             = gridgraph.Voisins
            NoeudsPeripheriques = gridgraph.NoeudsPeripheriques

            # Read input files
            pu_data    = CSV.read(pu_fname, header=1, delim=",")
            cf_data    = CSV.read(cf_fname, header=1, delim=",")
            bound_data = CSV.read(bound_fname, header=1, delim=",")

            # Problem size
            N_pu = length(pu_data.id)
            N_cf = length(targets)
            N_bd = length(bound_data.boundary)

            # Problem ranges
            PlanningUnits = collect(1:N_pu)
            ConservationFeatures = collect(1:N_cf)

            # Cost and status of planning units
            Cost = zeros(N_pu,1)
            IsLockedOut = zeros(N_pu,1)
            LockedOut = Vector{Int64}()
            for j in 1:N_pu
                Cost[j,1] = pu_data.cost[j]
                #Cost[j,1] = 1
                IsLockedOut[j,1] = pu_data.is_locked_out[j]
                if IsLockedOut[j,1] == 1
                    push!(LockedOut,j)
                end
            end

            # Amount and targets of conservation features
            Amount = zeros(N_cf,N_pu)
            Targets = zeros(N_cf,1)
            for i in 1:N_cf
                #eval(Meta.parse("cfi = cf_data.cf$(i)"))
                Amount[i,1:N_pu] = cf_data[:,i+1]
                Targets[i,1] = targets[i] * sum(Amount[i,1:N_pu] .* (1 .- IsLockedOut))
            end

            # Boundary length of vertices between two nodes
            BoundaryLength = Dict{Pair{Int,Int},Int}()
            for k in 1:N_bd
                BoundaryLength[bound_data.id1[k]=>bound_data.id2[k]] = bound_data.boundary[k]
                BoundaryLength[bound_data.id2[k]=>bound_data.id1[k]] = bound_data.boundary[k]
            end

            # Correction
            BoundaryCorrection = zeros(N_pu,1)
            for j in NoeudsPeripheriques
                BoundaryCorrection[j] = 4 - length(Voisins[j])
            end

            # constructor
            new(N_pu,N_cf,N_bd,PlanningUnits,ConservationFeatures,Cost,IsLockedOut,LockedOut,Amount,Targets,BoundaryLength,BoundaryCorrection,beta)

        end

    end


# ==============================================================================
#  RESERVE
# ==============================================================================
    struct Reserve
        x::Array{Int8,1}
        Size::Int64
        Cost::Float64
        Perimeter::Float64
        Score::Float64
        Coverage::Array{Float64,1}

        # reserve features
        function Reserve(x,instance)

            # conversion
            Voisins              = gridgraph.Voisins
            PlanningUnits        = instance.PlanningUnits
            ConservationFeatures = instance.ConservationFeatures
            Amount               = instance.Amount
            Cost                 = instance.Cost
            BoundaryLength       = instance.BoundaryLength
            BoundaryCorrection   = instance.BoundaryCorrection
            Beta                 = instance.Beta

            x = round.(x,digits=0)

            pu_reserve = PlanningUnits[x .== 1]
            Size = sum(x)
            Cost = sum(Cost[x .== 1])

            # Elements de la reserve
            Perimeter=0
            for j in PlanningUnits
                if x[j] == 1
                    Perimeter = Perimeter + sum(BoundaryLength[j=>k]*(1-x[k]) for k in Voisins[j])+BoundaryCorrection[j]*x[j]
                end
            end
            Score = Cost + Beta*Perimeter

            Coverage = Vector{Float64}()
            for i in ConservationFeatures
                push!(Coverage,sum(Amount[i,x .== 1]))
            end

            # constructor
            new(x,Size,Cost,Perimeter,Score,Coverage)


        end
    end

# ==============================================================================
#  RESERVE
# ==============================================================================
    struct PlotOptions
        png_res_width::Int64
        png_res_height::Int64
        xloc_lab::String
        yloc_lab::String
        text_size::Int64

        # reserve features
        function PlotOptions(png_res_width,png_res_height,xloc_lab,yloc_lab,text_size)

            # constructor
            new(png_res_width,png_res_height,xloc_lab,yloc_lab,text_size)


        end
    end
