clear						 
set more off			
capture log close 

local user = c(username)
display "`user'"

/* Stores filepath conditionally */
if ("`user'" == "erick") {
    global filepath "/home/erick/TEMP/"
}

if ("`user'" == "yaelb") {
    global filepath "C:\\Users\\yaelb\\OneDrive\\Documents\\Bocconi\\Magistrale\\Secondo Semestre\\micrometrics\\Assignment3\\stata_files\\"
}

if ("`user'" == "Clément Simon") {
    global filepath "C:\Users\Clément Simon\Documents\Etudes\2025-2026\S2\Microeconometrics\Problem Set 3\files\"
}

if ("`user'" == "zoedilieto") {
    global filepath "/Users/zoedilieto/Desktop/PS 3/stata_files/"
}

cd "$filepath"

*******EXERCISE 1: 

**ssc install rdrobust 
**ssc install rddensity 
**ssc install lpdensity
**ssc install outreg2

**POINT A: (compare)

use pset_3.dta, clear

*Plot treatment against running variable
rdplot T X, c(0) p(1) kernel(triangular) ///
    graph_options(ytitle("Treatment Variable") ///
		xtitle("Running Variable") ///
		title("RD Plot: Islamic Vote Margin 1994 (X) on Islamic Mayor in 1994 (T)") ///
		name(rdplot_T_X, replace))

* Export graph to current directory
graph export "rdplot_T_X.png", replace

/*Comment:In the plotted Regression Discontinuity Design, the treatment variable (Islamic Mayor in 1994)  goes from 0 to 1 around the cutoff. Therefore, such a design is a Sharp Regression Discontinuity design.  
This design is noticed because treatment (having an Islamic mayor) is entirely determined by the sign of X (the islamic party's margin). In other words, all those municipalities with a positive Islamic vote margin (Running Variable) has an Islamic mayor (Treatment Variable). T1 is therefore satisfied. 

Such a design is different from a Fuzzy RD, where the probability of treatment at the cutoff is not so neat (no clear jump from 0 to 1 probability of treatment), and there may be units above the cutoff that do not receive the treatment.*/

**Point B. 

* Define covariates
local covs "hischshr1520m i89 vshr_islam1994 partycount lpop1994 merkezi merkezp subbuyuk buyuk"

cap matrix drop R
foreach z in `covs' {
    qui rdrobust `z' X, c(0) p(1) kernel(triangular) bwselect(mserd)
	matrix R = nullmat(R) \ (e(h_l), e(tau_cl), e(pv_cl), e(N_h_l) + e(N_h_r)) 
}

**Check on the ffective_Number_of_obs (the weight issue)***
mat rownames R = `covs'
mat colnames R = "MSE_Optimal_bandwidith" "RD_Estimator" "p_value" "Effective_Number_of_obs"

mat list R

*create Table 1 and save it
preserve
clear 

svmat R, names(col)

gen Label = ""
local i = 1

foreach z in `covs' {
    replace Label = "`z'" in `i'
    local ++i
}

order Label MSE_Optimal_bandwidith RD_Estimator p_value Effective_Number_of_obs 

*save using out sheet: 
outsheet using "Table1.csv", comma replace


restore
/* Comment: All p-values are well above 0.1, and RD estimates are small 
and insignificant for all 9 baseline covariates. This confirms that 
pre-determined characteristics do not jump at the cutoff, supporting 
the continuity assumption underlying our RD design (T2 satisfied). */

***Point C: 


local covs "hischshr1520m i89 vshr_islam1994 partycount lpop1994 merkezi merkezp subbuyuk buyuk"

*reader-friendly labels
label variable hischshr1520m "High school share of men aged 15-20"
label variable i89 "Islamic Mayor in 1989"
label variable vshr_islam1994 "Islamic vote share in 1994"
label variable partycount "Number of parties receiving 1 vote"
label variable lpop1994 "Log population in 1994"
label variable merkezi "District center"
label variable merkezp "Province center"
label variable subbuyuk "Sub-metropolitan center"
label variable buyuk "Metropolitan center"

local i = 1

foreach z in `covs' {
	local title : variable label `z'

    rdplot `z' X, c(0) p(1) ///
        graph_options(title("`title'", size(small)) legend(off))
    
    graph rename g`i', replace
    local ++i
}

*combine graphs into one
graph combine g1 g2 g3 g4 g5 g6 g7 g8 g9
graph export Graph_1.pdf, replace

*** Point D: 

use pset_3.dta, clear
*Take the optimal bandwidth as a range: 
rdrobust Y X, c(0)
local h_left = -e(h_l)
local h_right = e(h_r)

** Plot the density of running variable "continuous" at the cutoff
rddensity X, c(0) plot plot_range(`h_l' `h_r')
graph rename density_plot, replace

* Plot the Histogram: 
local h_l = e(h_l)
local h_r = e(h_r)
twoway ///
    (histogram X if (X >= -`h_l' & X < 0), color(red%50) bin(30)) ///
    (histogram X if (X >= 0 & X <= `h_r'), color(blue%50) bin(30)), ///
    xline(0, lcolor(black)) ///
    legend(label(1 "Below") label(2 "Above")) ///
    title("Running Variable Distribution")

graph rename histogram_plot, replace

graph combine density_plot histogram_plot
graph export Graph_2.pdf, replace



*** Point E: 

* CKT density test
rddensity X, c(0)
local T = e(T_q)
local pv = e(pv_q)
display "T-stat: `T', p-value: `pv'"

/*Comment: 
rddensity provides a manipulation test for regression discontinuity designs and in this case we check for the manipulation of the running variable (Islamic Vote margin in 1994) around the cutoff (X=0). In other words, we test whether the treatment assignment is random near the cutoff. 
Given that the p-value is large (p-value = 0.1634) we fail to reject H0 (i.e. continuity of X at cutoff), suggesting no evidence of manipulation of the running variable by candidates or municipalities. This no-manipulation is expected given that this is an institutional setting of elections in a democratic country. Also it would be hard to manipulate the running variable just around cutoff because they are -at least to some extent- unknown in advance.

rddensity also runs binomial tests to compare the number of observations just above or just below X=0 in symmetric windows. Even though some large windows show imbalance (significantly higher number of observations on one side with respect to the other), the lack of unbalance in smaller windows suggests that manipulation is unlikely. 
This is favorable to the validity of our RD design (T3 satisfied).*/

*** Point F: 

foreach cutoff in -10 -5 5 10 {
	rdrobust Y X, c(`cutoff') p(1) ///
		kernel(triangular) bwselect(mserd)
	display "Cutoff `cutoff': " ///
		"coef=" e(tau_cl) " pval=" e(pv_rb)
}

/*Comment:
In this first placebo I estimate RD effects at alternative cutoffs −10, −5, 5, 10 using the full sample. The placebo cutoffs of -5, 5, 10 present insignificant estimates (p-values > 0.1). 

However, at c = -10 there is a statistically significant discontinuity. Suggesting that the performed RD is mostly valid, but there might be concerns about misspecification or a smooth nonlinearity being misinterpreted as a discontinuity (given that the continuity is not completely smooth when c is different from 0). Still, this result has to be taken cautiously given that we have used the full sample to estimate the continutiy over these cutoffs, which means that the discontinuity at -10 may be partially driven by the treatment effect at X=0 (which is the point of the actual treatment). 

We also consider that this result is likely driven by the highly unbalanced sample at that cutoff (2017 obs left vs 612 right) and the large distance from our true cutoff (Islamic parties lost by more than 10 points), making it less informative for our validity test.

For the second placebo test, we estimate the same placebo cutoffs but restrict the sample so that each placebo cutoff is tested only within one side of the true cutoff in the following lines. Meaning that for negative placebo cutoffs we estimate continuity of obervations that are only negative (X<0), while for positive cutoffs those that are positive (X>=0). */

use pset_3.dta, clear

cap matrix drop R
local cutoffs "-10 -5 5 10"
matrix define R = J(4,6,.)

matrix colnames R = Cutoff Bandwidth RD_Estimator SE CI_lower CI_upper

local k = 1

foreach c of local cutoffs {

    if `c' < 0 {
        quietly rdrobust Y X if X < 0, c(`c') p(1) ///
            kernel(triangular) bwselect(mserd)
    }
    else {
        quietly rdrobust Y X if X >= 0, c(`c') p(1) ///
            kernel(triangular) bwselect(mserd)
    }

    matrix R[`k',1] = `c'
    matrix R[`k',2] = e(h_l)
    matrix R[`k',3] = e(tau_cl)
    matrix R[`k',4] = e(se_tau_cl)
    matrix R[`k',5] = e(tau_cl) - invnormal(0.975)*e(se_tau_cl)
    matrix R[`k',6] = e(tau_cl) + invnormal(0.975)*e(se_tau_cl)

    local ++k
}

matrix list R

* Export table using outsheet
preserve
clear

svmat R, names(col)

format Bandwidth RD_Estimator SE CI_lower CI_upper %9.3f

outsheet using "placebo_cutoffs.csv", comma replace

restore

 


/*Comment: 

Checking also on the confidence intervals as anticipated, we can see that all CI estimated now contain zero and present relatively large p-values. Thereofre, we have evidence that  show that discontinuities in our running variable and outcomes do not exist away from our cutoff (T4 satisfied. )
*/

** Point G 
use pset_3.dta, clear

rdplot Y X, c(0) p(1) nbins(40) binselect(es) ///
    graph_options(ytitle("Outcome") ///
    xtitle("Running Variable") ///
    title("RD Plot: Outcome on Islamic Mayor in 1994"))
	
graph export "rdplot_Y_X.png", replace


** Point H: 

*triangular kernel 
rdrobust Y X, c(0) p(1) bwselect (mserd)

*Saving Optimal bandwidth for later - assuming it is symmetric. 
local opt_i = e(h_l)
local right_bandwidth = e(e_r) 


rdrobust Y X, c(0) p(1) kernel (uniform)

/*
Triangular Kernel: there is a 3 point estimate RD effect, significant at the 10% level.

Uniform kernel: effect is of the same magnitude and in the same direction (3,2), this time significant at the 5% level.

This means that having an Islamic mayor increases the share of women aged 15-20 completing high school by about 3 percentage points. This effect is relative to a mean of 0.140 (from table 1), and represents more than 0.3 standard deviations (SD = 0.090 for Islamic municipalities). 
Both metrics suggest a economically meaningful effect.

Also, let us notice that triangular and uniform kernels had roughly the same number of observations - although weight given to observations could differ, as triangular kernel gives higher weights to observations closer to cutoff.
*/

**Point I

forvalues j = 1/4 {
    gen X`j' = X^`j'
    gen TX`j' = T * X^`j'
}



* Global fourth-order polynomial regression
reg Y T X X2 X3 X4 TX1 TX2 TX3 TX4 
* Export regression table
outreg2 using "poly_regression_results.xls", ///
    replace excel dec(3) ///
    ctitle("Fourth-order polynomial")

*Comment: The global polynomial regression of fourth order displays a RD coefficient estimate on T (having an Islamic mayor elected) that is 3.7, significant at the 5% level and consistent with the rdrobust estimates in H.
*However, this approach is sensitive to the choice of polynomial order and can be distorted by observations far from the cutoff. The global approach indeed uses all 2,629 observations.

**Point J 

use pset_3.dta, clear


rdrobust Y X, c(0) p (1) kernel(triangular) bwselect (mserd)
local opt_bw = e(h_l)

display "Optimal bandwidth = `opt_bw'"

/*Comment: I first recover the MSE-optimal bandwidth from rdrobust and then restrict the sample to observations within that bandwidth around the cutoff.*/

gen TXj = T * X
reg Y T X TXj if abs(X) <= `opt_bw'

* Save regression table
outreg2 using "point_j_local_linear.xls", ///
    replace excel dec(3) ///
    ctitle("Local linear OLS within mserd bandwidth")


/* Comment: The local linear regression within the optimal bandwidth (h=17.24, yielding n=795) gives a coefficient of 3.06 (significant at 5%), close but not identical to H's 3.02. The small difference arises because rdrobust uses a triangular kernel (weighting observations by distance to cutoff), while the simple OLS regression within the bandwidth gives equal weight to all observations. The local approach is an approximation of rdrobust but not exact. */

** Point K

rdrobust Y X , c (0) p (1) bwselect ( mserd )
local opt_bw = e(h_l)
cap matrix drop R
matrix R = J(5 , 3 , .)
local i = 1
foreach m in 0.5 0.75 1 1.25 1.5 {
local bw = `opt_bw' * `m'
rdrobust Y X , c (0) p (1) h(`bw')
matrix R[ `i' , 1] = e( tau_cl )
matrix R[ `i' , 2] = e( ci_l_rb )
matrix R[ `i' , 3] = e( ci_r_rb )
local i = `i' + 1
}
matrix colnames R = coef ci_lo ci_hi

clear
 
svmat R, names(col)
gen mult = _n * 0.25 + 0.25
twoway (rcap ci_lo ci_hi mult) ///
       (scatter coef mult, mcolor(navy)), ///
       yline(0, lpattern(dash)) ///
       legend(off) ///
       xtitle("BW Multiplier") ///
       ytitle("RD Estimate")
graph save "graph_3.gph", replace
graph export "graph_3.png", replace

** Comment: The point estimate seems consistent across bandwidths, in magnitude and direction. We can notice that the confidence interval reduces as multiplier goes up, which is in line with the number of observations going up and therefore a more accurate point estimate. This is also confirmed by the p value going down as bandwidth increases. 
* There is evidence that our results are robust to bandwidth choice.
* The estimates are fairly robust in magnitude and sign: across bandwidth multipliers from 0.5 to 1.5, the RD estimate remains positive and generally around 2–3 percentage points. However, the confidence intervals are wide, especially for smaller bandwidths, and often include zero. So the evidence is not very statistically precise. This concern is however attenuated by the previous checks we have run on the badnwidth selection, which also suggested robust results and limited sensitivity to bandwidth choice.
* Wrapping up, we have checked that the 4 assumptions are verified and performed a robustness check on the bandwidth and on the functional form. These analyses confirmed the validity of our RD design. 



*EXERCISE 2 
use fraud_pcenter_final.dta, clear

*----- Question 1 -----

*First we need to work on the distance, as initially _dist basically means distance in absolute value. Following the author, we make _dist negative if there is no coverage (so negative distance means we are outside the boundary of coverage, while positive distance means that we are within coverage). 

gen signed_dist = _dist 
replace signed_dist = -_dist if cov == 0

*Now plot the relation between actual coverage and our proxy estimator _dist of the distance of the polling location and the closest point with coverage. If the proxy is ok, we should see a clear jump to 1 (indicator for having coverage) when distance becomes 0 or more. 
rdplot cov signed_dist, c(0)
graph export "regression_function_fit.png", replace

*the plot shows clearly that in general for polling stations proxied outside the coverage areas the cov variable is equal to 0 and for polling stations proxied inside the coverage area cov = 1. However, there clearly is some noise around the cutoff. This is expected, since we know that _dist (and therefore signed_dist) is a proxy. We are therefore working with a fuzzy RDD. 

*now estimate the RD with cov as dependent variable 
rdrobust cov signed_dist, c(0) p(1) ///
    kernel(triangular) bwselect(mserd) 
 
*this is a fuzzy RD design: the coverage doesn't precisely jump from 0 to 1 when the distance get to 0. This makes sense, as the distance here is partly computed using a proxy. 

/*In order for the one-dimentional measure of distance to be valid, first one needs to remember the usual RD assumptions: 
1. continuity at the cutoff for both the potential outcomes  (which in this case is not cov, but some measure related to fraud)
2. Also need to assume that selection into tratment (here, coverage) is going to be independent of potential outcomes
3. Other covariates being balanced around the cutoff
4. Relevant first stage (if too weak, the estimated effect on fraud will be imprecise)

However, here it is important to note that one other assumption has to hold, related to how the proxy work: we should be able to assume that the proxy is not related to other state characteristics or to later outcomes such as fraud rate. If some states with certain characteristics systematically appear within or outside the coverage bands, this could bias the results (either upwards or downwards). 

Note that the estimates of rdrobust seem pretty weak, the effect is small and not super significant! 
*/

*----- Question 2 ------
/*The original RD designed of the paper should not be changed if the paper itself was already identifying a fuzzy RD. One should just interpret the results as an "intent to treat" effect.  

For instance, in the additional results section the author takes into account that there could be spillover effects of coverage and that corrupt candidates could respond strategically to coverage by reallocating fraud to polling centers just outside coverage areas. Both these two would lead to a fuzze RD, where positive spillovers come from being close to coverage and negative spillovers arive from the polling stations being strategiacally just outside coverage. 
As said, this would lead to a fuzzy design. 
The author in the paper addresses these concerns, comparing fraud levels across 2 km bands around the boundary on the noncoverage side (using polling centers within 10km but further than 10km as comparison), and finding no significant spikes or drops in fraud measures.  
Nonetheless, this would mean that if the design is fuzzy and the phone coverage boundaries work as said, the design would work as well. 

However, it is important to note that this would also require that there is no systematic correlation between erorrs in the proxy for longitude and other characteristics of the polling station that also shape fraud outcomes. 
Moreover, we would need the design not to be too fuzzy, in order to allow precise enough identification of the treatment (here, coverage). It could be for instance that for some reason the phone coverage measure is mainly based on latitute, making the design fuzzy but powerful enough.

Another case in which the designed should not be changed is for some reason only latitude matter in shaping who gets coverage. In this case, even if the proxy for longitude is noisy, the RD design would be sharp. 
*/ 

* ---- Question 3 -----
*Start by computing the optimal bandwidth like the author does. 

use fraud_pcenter_final.dta, clear
gen signed_dist = _dist 
replace signed_dist = -_dist if cov == 0
 
recode region2 (3=1) (4=2)

drop if conflict==1



* Optimal bandwidth
gen temp = signed_dist

foreach var in /*600 95 ecc*/ comb comb_ind {
		rdbwselect vote_`var' temp if ind_seg50==1, fuzzy(cov) vce(cluster segment50)
		scalar hopt_`var'=e(h_mserd)
		forvalues r=1/2 {
			rdbwselect vote_`var' temp if ind_seg50==1 & region2==`r', fuzzy(cov) vce(cluster segment50)
			scalar hopt_`var'_`r'=e(h_mserd)
	}
}


* Control means
foreach var in /*600 95 ecc*/ comb comb_ind {
		sum vote_`var' if (cov==0 & ind_seg50==1 & _dist<=hopt_`var')
		scalar mean_`var'=r(mean)
		forvalues r=1/2 {
			sum vote_`var' if (cov==0 & ind_seg50==1 & _dist<=hopt_`var'_`r' & region2==`r')
			scalar mean_`var'_`r'=r(mean)
	}
}
*
foreach var in /*600 95 ecc*/ comb comb_ind {
		sum vote_`var' if (cov==0 & ind_seg50==1)
		scalar mean_`var'_all=r(mean)
		forvalues r=1/2 {
			sum vote_`var' if (cov==0 & ind_seg50==1 & region2==`r')
			scalar mean_`var'_`r'_all=r(mean)
	}
}


xtset, clear
xtset segment50 pccode

*B. Local Linear Regression (using distance as forcing variable)

*Note: Gonzaleg was using cov to signal that we were on the within-coverage side of the cutoff. However, this was only working when the RD design was sharp. Now, instead, we define an indicator to signal being on the right of the cutoff: 
gen right = (temp >= 0)

gen right_dist = right*temp
gen cov_dist = cov*temp


 foreach var in comb_ind comb {	
    * All regions
    xtivreg vote_`var' temp (cov cov_dist = right right_dist) ///
        if ind_seg50==1 & _dist<=hopt_`var', ///
        fe vce(robust)

    est store col1_a_`var'
  

	* Southeast
	xtivreg vote_`var' temp (cov cov_dist = right right_dist) ///
	if ind_seg50==1 & _dist<=hopt_`var'_1 & ///
	region2==1, ///
        fe vce(robust)
		est store col1_b_`var'
		
	* Northwest
	xtivreg vote_`var' temp (cov cov_dist = right right_dist) /// 
	if ind_seg50==1 & _dist<=hopt_`var'_2 & ///
	region2==2, ///
        fe vce(robust)
		est store col1_c_`var'
 }

*E. Export results
putexcel set "table2_replication.xlsx", replace

* Headers
putexcel A1 = "Outcome"
putexcel B1 = "All regions"
putexcel C1 = "Southeast"
putexcel D1 = "Northwest"

putexcel A2 = "At least one Category C fraud station"
putexcel A3 = "Share of votes under Category C fraud"

* Point estimates for vote_comb_ind
est restore col1_a_comb_ind
putexcel B2 = (_b[cov])

est restore col1_b_comb_ind
putexcel C2 = (_b[cov])

est restore col1_c_comb_ind
putexcel D2 = (_b[cov])

* Point estimates for vote_comb
est restore col1_a_comb
putexcel B3 = (_b[cov])

est restore col1_b_comb
putexcel C3 = (_b[cov])

est restore col1_c_comb
putexcel D3 = (_b[cov])




/*
As for the estimates interpretation: what the table reports is the coefficients for the effect of coverage (a dummy), estimated from a fuzzy RD design. Coverage is instrumented by a proxy for the distance from the closest point with coverage. 
Note that the design assumes linearity, but it allows for the slope to change after the cutoff (besides allowing for a jump at the cutoff). 

As for the results, they are reported for two outcomes of interest: an indicator for at least one fraudolent vote (type C fraud) in the polling station, and the share of type C faudolent votes in the polling station. 

When the effect of coverage is estimated across the whole country, we find that coverage decreases fraud by 13 percentage points for the dummy and by 12 percentage points for the share. 

However, if we look more into it, we note that for the southeast part of the country the impact is much bigger (respectively, 37 and 27 percentage points decrease in frauds if there is coverage). It seems that it's what drives the results, as for the northwest part of the county the effect is poisive but much smaller (4 and 3.8 pp), and likely not siificant. 

Note that, despite the exact numbers being different, we get the same pattern that the author gets. 

*/

