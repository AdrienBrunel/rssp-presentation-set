# ==============================================================================
#  VISUALISATION FUNCTIONS
# ==============================================================================

    ## Color to RGB vector -----------------------------------------------------
    function col2rgb(color)
        color_rgb = RGB(color)
        return [color_rgb.r,color_rgb.g,color_rgb.b]
    end

    ## RGB vector to color -----------------------------------------------------
    function rgb2col(color_rgb)
        return RGB(color_rgb[1],color_rgb[2],color_rgb[3])
    end

    ## Rectangle shape ---------------------------------------------------------
    rectangle(w, h, x, y) = Plots.Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])


    ## Visualisation input -----------------------------------------------------
    function visualisation_input(instance,gridgraph,plot_opt,plotgrid=false)

      xloc           = gridgraph.xloc
      yloc           = gridgraph.yloc
      N_pu           = gridgraph.N_pu
      N_x            = gridgraph.N_x
      N_y            = gridgraph.N_y
      LockedOut      = instance.LockedOut
      Cost           = instance.Cost
      Amount         = instance.Amount
      xloc_lab       = plot_opt.xloc_lab
      yloc_lab       = plot_opt.yloc_lab
      text_size      = plot_opt.text_size
      png_res_width  = plot_opt.png_res_width
      png_res_height = plot_opt.png_res_height

      lon_range = [minimum(gridgraph.xloc),maximum(gridgraph.xloc)]
      lat_range = [minimum(gridgraph.yloc),maximum(gridgraph.yloc)]
      lon_res = gridgraph.lon_seq[2]-gridgraph.lon_seq[1]
      lat_res = gridgraph.lat_seq[2]-gridgraph.lat_seq[1]

      if plotgrid==true
        # Grille
        Plots.plot(xlim=lon_range, ylim=lat_range, title="Grille", xlabel=xloc_lab, ylabel=yloc_lab, size=(png_res_width,png_res_height),legend=false)
        for k in 1:N_pu
          xc = xloc[k]
          yc = yloc[k]
          if LockedOut[k] == 1
              Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor="grey",linecolor="black")
          else
              Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor="white",linecolor="black")
          end
          Plots.annotate!([(xc,yc,Plots.text(@sprintf("%d",k),text_size))])
        end
        png(string(pic_dir,"/grid.png"))
      end

      # PU vs cost
      Plots.plot(xlim=lon_range, ylim=lat_range, title="Cost", xlabel=xloc_lab,
                 ylabel=yloc_lab, size=(png_res_width,png_res_height),legend=false)
      C  = palette([:white, :yellow, :orange, :red],100)
      z  = Cost
      z1 = minimum(z)
      z2 = maximum(z)
      Z  = collect(range(z1,z2,length=length(C)))
      for k in 1:N_pu
        xc = xloc[k]
        yc = yloc[k]
        zk = z[k]
        if z1!=z2
          idx = min(findall(Z .- zk .> 0)...,length(Z))
          t = (zk-Z[idx-1])/(Z[idx]-Z[idx-1])
          ck = t*col2rgb(C[idx])+(1-t)*col2rgb(C[idx-1])
        else
          idx = 1
          ck = col2rgb(C[idx])
        end
        Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor=rgb2col(ck),linecolor=rgb2col(ck))
        Plots.annotate!([(xc,yc,Plots.text(@sprintf("%.1f",zk),text_size))])
      end
      png(string(pic_dir,"/cost.png"))

      # PU vs CF
      for i in CF
          title = "PU vs CF$(i)"
          Plots.plot(xlim=lon_range, ylim=lat_range, title=title, xlabel=xloc_lab,
                     ylabel=yloc_lab, size=(png_res_width,png_res_height),legend=false)
          C  = palette([:white, :yellow, :orange, :red],100)
          z = Amount[i,:]
          z1 = minimum(z)
          z2 = maximum(z)
          Z  = collect(range(z1,z2,length=length(C)))
          for k in 1:N_pu
            xc = coords_data.xloc[k]
            yc = coords_data.yloc[k]
            zk = z[k]
            if z1!=z2
              idx = min(findall(Z .- zk .> 0)...,length(Z))
              t = (zk-Z[idx-1])/(Z[idx]-Z[idx-1])
              ck = t*col2rgb(C[idx])+(1-t)*col2rgb(C[idx-1])
            else
              idx = 1
              ck = col2rgb(C[idx])
            end
            if LockedOut[k] == 1
                Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor="grey",linecolor="grey")
            else
                Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor=rgb2col(ck),linecolor=rgb2col(ck))
            end
            Plots.annotate!([(xc,yc,Plots.text(@sprintf("%.1f",zk),text_size))])
          end
          png(string(pic_dir,"/cf$(i).png"))
      end

      return

    end

    ## Visualisation output ----------------------------------------------------
    function visualisation_output(reserve,instance,gridgraph,plot_opt,pic_name)

        xloc           = gridgraph.xloc
        yloc           = gridgraph.yloc
        N_x            = gridgraph.N_x
        N_y            = gridgraph.N_y
        N_pu           = instance.N_pu
        N_cf           = instance.N_cf
        Beta           = instance.Beta
        IsLockedOut    = instance.IsLockedOut
        Reserve        = reserve.x
        Size           = reserve.Size
        Cost           = reserve.Cost
        Perimeter      = reserve.Perimeter
        Score          = reserve.Score
        xloc_lab       = plot_opt.xloc_lab
        yloc_lab       = plot_opt.yloc_lab
        text_size      = plot_opt.text_size
        png_res_width  = plot_opt.png_res_width
        png_res_height = plot_opt.png_res_height

        lon_range = [minimum(gridgraph.xloc),maximum(gridgraph.xloc)]
        lat_range = [minimum(gridgraph.yloc),maximum(gridgraph.yloc)]
        lon_res = gridgraph.lon_seq[2]-gridgraph.lon_seq[1]
        lat_res = gridgraph.lat_seq[2]-gridgraph.lat_seq[1]
        xloc_lim = lon_range
        yloc_lim = lat_range

        title = @sprintf("Reserve solution\nN_x=%d | N_y=%d | N_pu=%d | N_cf=%d | Beta=%.1f \npu=%d | cost=%.1f | perimeter=%.1f | score=%.1f",N_x,N_y,N_pu,N_cf,Beta,Size,Cost,Perimeter,Score)

        Plots.plot(xlim=xloc_lim, ylim=yloc_lim, title=title, xlabel=xloc_lab,ylabel=yloc_lab, size=(png_res_width,png_res_height),legend=false)
        C  = palette([:white, :yellow, :orange, :red],100)
        z  = Reserve
        for k in 1:N_pu
            xc = xloc[k]
            yc = yloc[k]
            zk = z[k]

            if IsLockedOut[k] == 1
                Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor="grey",linecolor="grey")
            else
                if zk == 1
                    Plots.plot!(rectangle(lon_res,lat_res,xc-lon_res/2,yc-lat_res/2),fillcolor=:green,linecolor=:green)
                end
            end
        end
        png("$(pic_dir)/$(pic_name)")

        return
    end



# ==============================================================================
#  READ FUNCTIONS
# ==============================================================================

    ## Read informations -------------------------------------------------------
    function read_reserve_solution(model,gridgraph)

        # Lecture données du graphe de la grille
        Arcs   = gridgraph.Arcs
        Noeuds = gridgraph.Noeuds
        PlanningUnits = instance.PlanningUnits

        # variable de sélection des noeuds de la reserve
        x_opt = round.(Int,value.(model[:x]).data)

        # variable de linéarisation
        z_tmp = round.(Int,value.(model[:z]).data)
        z_opt = Dict{Pair{Int,Int},Int}()
        for d in Arcs
            z_opt[d] = 0
            if sum(findall(d .== Arcs[z_tmp .==1]))>0
                z_opt[d] = 1
            end
        end

        return x_opt,z_opt
    end

    ## Print informations ------------------------------------------------------
    function print_reserve_solution(x_opt,z_opt,instance,gridgraph)

        # Read grid and instance
        Voisins              = gridgraph.Voisins
        NoeudsPeripheriques  = gridgraph.NoeudsPeripheriques
        PlanningUnits        = instance.PlanningUnits
        ConservationFeatures = instance.ConservationFeatures
        Amount               = instance.Amount
        Cost                 = instance.Cost
        Targets              = instance.Targets
        BoundaryLength       = instance.BoundaryLength
        BoundaryCorrection   = instance.BoundaryCorrection
        Beta                 = instance.Beta


        # variable de sélection des noeuds de la reserve
        Reserve = PlanningUnits[x_opt[PlanningUnits] .== 1]
        Size = length(Reserve)
        println("Reserve is made of $(Size) planning units")
        println("Planning units selected in reserve are $(Reserve)")
        println("Reserve cost is $(sum(Cost[x_opt[PlanningUnits] .== 1]))")
        for i in ConservationFeatures
            cf_amount = round(sum(Amount[i,x_opt[PlanningUnits] .== 1]),digits=2)
            cf_target = round(Targets[i],digits=2)
            println("Reserve coverage of specie $(i) is $(cf_amount) while target is $(cf_target)")
        end

        # Elements de la reserve
        Perimetre=0
        for j in PlanningUnits
            if x_opt[j] == 1
                Perimetre = Perimetre + sum(BoundaryLength[j=>k]*(1-x_opt[k]) for k in Voisins[j])+BoundaryCorrection[j]*x_opt[j]
            end
        end
        Cout = sum(Cost[x_opt[PlanningUnits] .== 1])
        Score = Cout + Beta*Perimetre
        println("Reserve perimeter is $Perimetre")
        println("Reserve score is : Score = Cost + Beta x Perimeter = $(Cout) + $(Beta) x $(Perimetre) = $(Score)")

        return Size,Perimetre,Cout,Score
    end

    function PseudoDistance(x,y)
        return (x' * (1 .- y))[1]
    end
