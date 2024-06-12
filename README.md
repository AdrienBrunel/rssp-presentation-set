# rssp_presentation_set
Main goal is to produce a presentation set for the reserve site selection problem by explicitly accounting for differences between successive alternative solutions. 

# Presentation set
This code is developed alongside the published work "Brunel, A., Omer, J. & Lanco Bertrand, S. Producing a Diverse Set of Near-Optimal Reserve Solutions with Exact Optimisation. Environ Model Assess 28, 619–634 (2023). https://doi.org/10.1007/s10666-022-09862-1". 

# General information
1. If this is the first time the code run on your computer, you have to install manually the packages loaded in load_path_pkg.jl.  

2. Julia version for this code is 1.4.2

3. Fill in parameters at the beginning of the script main.jl to simulate the scenario you want. 

4. If you want to run the code with your own data, you have to put the input files (pu.csv, cf.csv, bound.csv, coords.csv) to the good format in a given folder. Then, this folder must be place in 1_data. To see the specific format, you can look in the examples provided.  

5. In main.jl, give a name to the scenario your want to simulate. Set "gen", "opti" and "visu" variables to true values if you want to generate input data, solve the reserve site selection optimisation problem and visualize the results. 

6. main.jl is the only script you need to run. 

7. Results of the scenario simulation will be produced and stored in /3_results/your_scenario_name/ inside .csv files

8. Figures associated with the results will be produced and stored in /4_report/pictures/your_scenario_name/ 
