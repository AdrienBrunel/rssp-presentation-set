# ==============================================================================
#  NOMINAL RESERVE SITE SELECTION ; MINSET ; WITH BLM ; WITH LINEARIZATION
# ==============================================================================
	function reserve_site_selection_model(instance,gridgraph)

		# Lecture données
		Voisins              = gridgraph.Voisins
		Arcs                 = gridgraph.Arcs
		NoeudsPeripheriques  = gridgraph.NoeudsPeripheriques
		ConservationFeatures = instance.ConservationFeatures
		PlanningUnits 		 = instance.PlanningUnits
		LockedOut 		     = instance.LockedOut
		Amount 				 = instance.Amount
		Cost                 = instance.Cost
		Targets              = instance.Targets
		BoundaryLength       = instance.BoundaryLength
		BoundaryCorrection   = instance.BoundaryCorrection
		Beta   				 = instance.Beta

		# Déclaration du modèle
		m = Model(Gurobi.Optimizer)
		set_optimizer_attribute(m, "TimeLimit", 600)

		# Variables de décision
		@variable(m, x[PlanningUnits], Bin); # variable de sélection du noeuds j dans le graphe de la réserve
		@variable(m, z[Arcs], Bin);          # variable de linéarisation du périmètre quadratique

		# Minimiser le coût de la réserve
		@objective(m, Min, sum(Cost[j]*x[j] for j in PlanningUnits) + beta*sum(BoundaryLength[d]*(x[d[1]]-z[d]) for d in Arcs) + Beta*sum(BoundaryCorrection[j]*x[j] for j in NoeudsPeripheriques))

		# La réserve doit réaliser les cibles écologiques
		@constraint(m, cibles[i in ConservationFeatures], sum(Amount[i,j]*x[j] for j in PlanningUnits) >= Targets[i])

		# linearization constraints
		@constraint(m, lin_z1[d in Arcs],  z[d] - x[d[1]] <= 0)
		@constraint(m, lin_z2[d in Arcs],  z[d] - x[d[2]] <= 0)

		# locked out planning units constraints
		@constraint(m, locked_out[j in LockedOut],  x[j] == 0)

		return m
	end


# ==============================================================================
#  BUILD A PORTFOLIO OF SOLUTIONS BY ITERATIVELY MAXIMIZING PSEUDO-DISTANCE
# ==============================================================================
	function presentation_set_max_pdistance(instance,gridgraph,N_sol,gap)

		# Lecture données
		Voisins              = gridgraph.Voisins
		Arcs                 = gridgraph.Arcs
		NoeudsPeripheriques  = gridgraph.NoeudsPeripheriques
		ConservationFeatures = instance.ConservationFeatures
		PlanningUnits 		 = instance.PlanningUnits
		N_pu 		 		 = instance.N_pu
		LockedOut 		     = instance.LockedOut
		Amount 				 = instance.Amount
		Cost                 = instance.Cost
		Targets              = instance.Targets
		BoundaryLength       = instance.BoundaryLength
		BoundaryCorrection   = instance.BoundaryCorrection
		Beta   				 = instance.Beta

		# Collection des solutions
		X = zeros(N_pu,N_sol)

		# Déclaration du modèle
		m = Model(Gurobi.Optimizer)
		set_optimizer_attribute(m, "TimeLimit", 1800)

		# Variables de décision
		@variable(m, x[PlanningUnits], Bin); # variable de sélection du noeuds j dans le graphe de la réserve
		@variable(m, z[Arcs], Bin);          # variable de linéarisation du périmètre quadratique

		# Minimiser le coût de la réserve
		@objective(m, Min, sum(Cost[j]*x[j] for j in PlanningUnits) + beta*sum(BoundaryLength[d]*(x[d[1]]-z[d]) for d in Arcs) + Beta*sum(BoundaryCorrection[j]*x[j] for j in NoeudsPeripheriques))

		# La réserve doit réaliser les cibles écologiques
		@constraint(m, cibles[i in ConservationFeatures], sum(Amount[i,j]*x[j] for j in PlanningUnits) >= Targets[i])

		# linearization constraints
		@constraint(m, lin_z1[d in Arcs],  z[d] - x[d[1]] <= 0)
		@constraint(m, lin_z2[d in Arcs],  z[d] - x[d[2]] <= 0)

		# locked out planning units constraints
		@constraint(m, locked_out[j in LockedOut],  x[j] == 0)

		optimize!(m);
		xhat = value.(m[:x]).data
		zhat = objective_value(m)
		X[:,1] = xhat

		# recursive algo to to find most pseudo-distant alternative solution
		k = 1
		@variable(m, delta)
		@objective(m, Max, delta)
		@constraint(m, budget, sum(Cost[j]*x[j] for j in PlanningUnits) + beta*sum(BoundaryLength[d]*(x[d[1]]-z[d]) for d in Arcs) + Beta*sum(BoundaryCorrection[j]*x[j] for j in NoeudsPeripheriques) <= (1+gap)*zhat)
		while (termination_status(m) != MOI.INFEASIBLE_OR_UNBOUNDED) & (k<N_sol)
			@constraint(m, sum(xhat[j,1]*(1-x[j,1]) for j in PlanningUnits) >= delta)
			t1 = time_ns()
			optimize!(m);
			t2 = time_ns()
			computation_time = round((t2-t1)/1e9,digits=2)
			println("Alternative $(k) found in $(computation_time)s")

			if (termination_status(m) != MOI.INFEASIBLE_OR_UNBOUNDED)
				k = k+1
				xhat = value.(m[:x]).data
				zhat = objective_value(m)

				X[:,k] = xhat
				for tmp in 1:(k-1)
					@printf("d(x^%d,x)=%d\n",tmp-1,PseudoDistance(X[:,tmp],xhat))
				end
			end
		end

		return X[:,1:k],m
	end



# ==============================================================================
#  BUILD A PORTFOLIO OF SOLUTIONS BY ITERATIVELY CONSTRAINING PSEUDO-DISTANCE
# ==============================================================================
	function presentation_set_con_pdistance(instance,gridgraph,N_sol,dpu)

		# Lecture données
		Voisins              = gridgraph.Voisins
		Arcs                 = gridgraph.Arcs
		NoeudsPeripheriques  = gridgraph.NoeudsPeripheriques
		ConservationFeatures = instance.ConservationFeatures
		PlanningUnits 		 = instance.PlanningUnits
		N_pu 		 		 = instance.N_pu
		LockedOut 		     = instance.LockedOut
		Amount 				 = instance.Amount
		Cost                 = instance.Cost
		Targets              = instance.Targets
		BoundaryLength       = instance.BoundaryLength
		BoundaryCorrection   = instance.BoundaryCorrection
		Beta   				 = instance.Beta

		# Collection des solutions
		X = zeros(N_pu,N_sol)

		# Déclaration du modèle
		m = Model(Gurobi.Optimizer)
		set_optimizer_attribute(m, "TimeLimit", 1800)

		# Variables de décision
		@variable(m, x[PlanningUnits], Bin); # variable de sélection du noeuds j dans le graphe de la réserve
		@variable(m, z[Arcs], Bin);          # variable de linéarisation du périmètre quadratique

		# Minimiser le coût de la réserve
		@objective(m, Min, sum(Cost[j]*x[j] for j in PlanningUnits) + beta*sum(BoundaryLength[d]*(x[d[1]]-z[d]) for d in Arcs) + Beta*sum(BoundaryCorrection[j]*x[j] for j in NoeudsPeripheriques))

		# La réserve doit réaliser les cibles écologiques
		@constraint(m, cibles[i in ConservationFeatures], sum(Amount[i,j]*x[j] for j in PlanningUnits) >= Targets[i])

		# linearization constraints
		@constraint(m, lin_z1[d in Arcs],  z[d] - x[d[1]] <= 0)
		@constraint(m, lin_z2[d in Arcs],  z[d] - x[d[2]] <= 0)

		# locked out planning units constraints
		@constraint(m, locked_out[j in LockedOut],  x[j] == 0)


		optimize!(m);
		xhat = value.(m[:x]).data
		zhat = objective_value(m)
		X[:,1] = xhat

		# recursive algo to cut known solutions
		k = 1
		while (termination_status(m) != MOI.INFEASIBLE_OR_UNBOUNDED) & (k<N_sol)
			@constraint(m, sum(X[j,k]*(1-x[j]) for j in PlanningUnits) >= dpu)
			t1 = time_ns()
			optimize!(m);
			t2 = time_ns()
			computation_time = round((t2-t1)/1e9,digits=2)
			println("Alternative $(k) found in $(computation_time)s")

			if (termination_status(m) != MOI.INFEASIBLE_OR_UNBOUNDED)
				k = k+1
				X[:,k] = value.(m[:x]).data
				for tmp in 1:(k-1)
					@printf("d(x^%d,x)=%d\n",tmp-1,PseudoDistance(X[:,tmp],X[:,k]))
				end
			end
		end

		return X[:,1:k],m
	end
