# rssp-presentation-set
The main goal is to produce a presentation set for the reserve site selection optimisation problem by explicitly accounting for differences between successive alternative solutions. 

# Publication
This code is developed alongside the published work "Brunel, A., Omer, J. & Lanco Bertrand, S. **Producing a Diverse Set of Near-Optimal Reserve Solutions with Exact Optimisation**. _Environ Model Assess 28, 619–634 (2023)_. [https://doi.org/10.1007/s10666-022-09862-1](https://doi.org/10.1007/s10666-022-09862-1)". 

# Guidelines
* If this is the first time the code run on your computer, you have to install manually the packages loaded in `load_path_pkg.jl`.  
* Fill in parameters at the beginning of the script `main.jl` to simulate the scenario you want. 
* If you want to run the code with your own data, you have to put the input files (`pu.csv`, `cf.csv`, `bound.csv`, `coords.csv`) to the good format in a given folder. Then, this folder must be place in `/1_data/`. To see the specific format, you can look in the examples provided.  
* In `main.jl`, give a name to the scenario your want to simulate. Set *gen*, *opti* and *visu* variables to true values if you want to generate input data, solve the reserve site selection optimisation problem and visualize the results. 
* `main.jl` is the only script you need to run. 
* Results of the scenario simulation will be produced and stored in `/3_results/your_scenario_name/` inside .csv files
* Figures associated with the results will be produced and stored in `/4_report/pictures/your_scenario_name/`

# Infos
* Julia version used is 1.4.2
* OS used is Ubuntu 18.04 
