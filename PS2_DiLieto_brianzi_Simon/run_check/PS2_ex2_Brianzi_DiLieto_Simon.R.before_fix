################################################################################
#PS2: 
################################################################################
# Template of R script to answer problem set
# Group number: 
# Group composition: Yael Brianzi, Zoe Di Lieto, Clement Simon

# Get the username
user <- Sys.info()["user"]
print(user)

# Define file path conditionally
if (user == "erick") {
  filepath <- "/home/erick/TEMP/"
} else if (user == "yaelb") {
  filepath <- "C:\\Users\\yaelb\\OneDrive\\Documents\\Bocconi\\Magistrale\\Secondo Semestre\\micrometrics\\Assignment2\\"
} else if (user == "Clément Simon") {
  filepath <- "C:\\Users\\Clément Simon\\Documents\\Etudes\\2025-2026\\S2\\Microeconometrics\\Problem Set 2\\files\\"
} else if (user == "zoedilieto") {
  filepath <- "/Users/zoedilieto/Desktop/micrometrics/PS2/files/"
}

# Print the selected file path
print(paste("File path set to:", filepath))

## POINT A: 
#install.packages("grf")
#install.packages("rlang", dependencies = TRUE)
#install.packages("dplyr", dependencies = TRUE)



library(dplyr)
library(haven); library(grf)
auto <- read.csv("/Users/zoedilieto/Desktop/micrometrics/PS2/files/expanded_data.csv", sep=",")
auto <- auto[(auto$lfdivlaw >= 1969 & auto$lfdivlaw <= 1973) | auto$lfdivlaw == 2000, ]
#here we keep only the states in the sample adopting the unilateral divorce law between 1969 and 1973, and the ones adopting it in 2000. 

#For each county, compute how divorce rates changed from 1968 to 1978, and compare that change between states that adopted unilateral divorce laws and those that didn’t. 
auto$st_code<- auto$st
auto <- auto %>%
  group_by(st_code, county_id) %>%
  mutate(div_rate_fd = div_rate_sim[year == 1978] - div_rate_sim[year == 1968]) #For each county, you pick the 1968 and 1978 values and compute their difference in divorce rates, then attach that difference to every observation in that county.

auto$treated <- ifelse(auto$lfdivlaw >= 1969 & auto$lfdivlaw <= 1973, 1, 0) #encode the treatment variable into a dummy. 
auto <- auto[auto$year == 1968, ] 

auto$urban <- ifelse(auto$urbanization == "Urban", 1, 0) #encode the straing avriable into a dummy

# Prepare data
X <- as.matrix(auto[, c("education_rate", "childcare_availability", "unemployment_rate", "median_income", "urban", "marriage_rate", "religious_adherence", "alcohol_consumption", "domestic_violence_rate", "women_labor_force_participation", "housing_cost", "crime_rate", "social_services_spending")])
Y <- as.numeric(auto$div_rate_fd)
W <- auto$treated # treatment indicator
##N.B. In the X variable I did not include the varibles years (only two years in the dataset so these may be already accounted for with the treament)
# and county_id (state instead might have some FE that could be taken into account). 
##N.B.2 - we should exclude all variables that could be affected by the treatment, which would introduce bias. 
#"All the variables we selected look like pre-treatment county characteristics, so the selection is appropriate. However, we flag that religion and women workforce might influence treatment year and introduce endogeneity, as discussed later.

# Fit causal forest
cf <- causal_forest(X, Y, W, num.trees = 2000, seed = 123)

# Average treatment effect (ATE)
ate <- average_treatment_effect(cf, target.sample = "all") 
cat("ATE:", ate[1], "SE:", ate[2], "\n")

#ATE : 0.02705806 SE: 0.07137284 

## This analysis exploits the US divorce rate date to compare the couties that 
#introduced the Unilateral divorce reform between 1969 and 1973, and those that 
# introduced it in the year 2000. 
# In point 1.C we found that, when controlling for being a state that implemented, 
#there is no significant effect of the reform for the states that implemented the 
#Unilateral divorce law after 1978.
# Such a result is consistent with the ATE found using the causal forest, as the 
#estimate is highly non-significant and close to zero. 

## POINT B: 

# (i). Best Linear Projection (BLP): does tau(x) vary with X?
blp <- best_linear_projection(cf, X) 
print(blp)

#The Best Linear Projection (BLSP) reveals staistically significant heterogeneity 
#in treatment effects. 
# More specifically, regigious adeherence is strongly negatively associated to the treatment effect. 
# In other words, more religious counties reveal less of an effect of unilateral 
#divorce laws on divorce rates. 
# Also, women labor force participation is positively associated to the treatment effect: 
# counties where participation is high, present a stronger divorce rate when unilateral 
#doivorce laws are implemented.
# Finally, the results also present a weak effect of the treatment for counties 
#with high domestic violence (p-value= 0.07), 
# meaning that the law might have a weak positive effect on the divorce rates. 

#(ii) Targeting operator characteristics: (explain whether estimated CATE are useful 
#for targeting treatment to the right people)

n <- nrow(X)
train <- sample(1:n, n / 2)
train.forest <- causal_forest(X[train, ], Y[train], W[train])
eval.forest <- causal_forest(X[-train, ], Y[-train], W[-train])
rate <- rank_average_treatment_effect(eval.forest,
                                      predict(train.forest, X[-train, ])$predictions)
plot(rate)

paste("AUTOC:", round(rate$estimate, 2), "+/", round(1.96 * rate$std.err, 2))
#> [1] "AUTOC: 0.2 +/ 0.1"

#The Targeting Operator Characteristics (TOC) presents a positive estimate, AUTOC = 0.31 
#with C.I. [0.13,0.49]. 
# Such a result implies that counties with higher predicted CATES, present a higher treatment effects 
#(i.e. the causal forest is able to meaningfully rank the counties by treatment effect). 

#GRAPH: The x-axis in the shows the counties we chose to treat based on the predicted 
#CATE (from the highest to the lowest), 
# and the y-axis shows the average treatment effect for the group selected at that 
#given q (treated fraction of counties). 
#The underlying rationale is that, the more counties get treated the lower the 
#average treatment effect will be. 
#In this specific case, the top 0.2-0.4 treated fraction of counties (q around 0.3) 
#yield to the highest treatment effect (around 0.6 increase in divorce rates). 
#Instead, extending the treatment to the entire population would yield to much smaller effects 
#on the divorce rates. 

#(iii) Plot the distribution of CATEs: 
hist(cate_hat, main = "Distribution of CATEs", xlab = "CATE")

#The distribution of CATE shows quite some dispersion, the rage goes from -0.4 to 0.6 predicted treatment effect. The graph shows an histogram, 
# where each bar represents the number of counties with a given predicted CATE. We can see that treatment varies a lot through counties and the reform
# does not affect all counties in the same way, proving a strong heterogeneous treatment effect. 

#Findings are consistent with BLS and TOC, proving both that the treatment effect depends on socio-economic factors and that some counties may have a 
#stronger response to the reform relative to others. 

#Variable importance (finding which covariuates most drive heterogeneity): 

varimp <- variable_importance(cf)
importance_df <- data.frame(variable = colnames(X),
                            importance = round(as.numeric(varimp), 3)) 

print(importance_df[order(-importance_df$importance), ])

#From this practice we select the most important variables driving heterogeneity, that are also the ones mentioned when analysing BLS since are those with a 
# significant coefficient in revealing heterogeneity in the sample. Thus we then plot their CATEs distribution. 

plot(auto$religious_adherence, cate_hat,
     xlab = "Religious Adherence", ylab = "CATE",
     main = "Conditional treatment effect by religious adeherence")
abline(h = 0, col = "red", lty = 2)

#From this graph we can see that (as estimated by the BLP) as the religious adherence increases within counties, the treatment effect decreases,  
# presenting a lower CATE. 

plot(auto$women_labor_force_participation, cate_hat,
     xlab = "Women Labor Force Participation", ylab = "CATE",
     main = "Conditional treatement effect by women labor force participation")
abline(h = 0, col = "green", lty = 2)

#Counties with a higher women labor force participation tend to have a stronger treatement effect (still the realtionship is weaker if compared 
# to the previous graph). 

plot(auto$domestic_violence_rate, cate_hat,
     xlab = "Domestic Violence", ylab = "CATE",
     main = "Conditional treatment effectby domestic variance")
abline(h = 0, col = "blue", lty = 2)

# There is a slight positive relation, i.e. counties with more domestic violence have a stronger tretment effect. Still, as already said when 
# analysing the BLS, the coefficient is weak in fact the distribution of CATE is quite sparse. 


## POINT C: 

# Results show strong heterogeneous treatment effects across counties of unilateral divorce laws, depending on relative socio-economic characteristics. 

# This analysis studies the effects of the introduction of unilateral divorce laws on the divorce rates of counties in the US between 1968 and 1978. 
# The framework that was implemented is a long-difference, where treated counties are those adopting the law between 1969 and 1973, while the control 
# group is formed by counties adopting the law after the 2000s. The causal forest is in this case adopted to estimate the Average Treatment Effect (ATE)
# and the Heterogeneous Treatment Effect (CATE). 

# The problem starts off by computing the ATE, that has a low and weakly significant estimate, suggesting that the overall effect of the treatment across counties
# is not very strong. Still, this result does not unceover the heterogeneity in the sample. In fact, looking at the distribution of CATEs across the sample we 
# pointed out that there is a high degree of heterogeneity that drives different results for counties that have different socio-economic characteristics. 

# The analysis first looks at the Best Linear Projection (BLS) that reveals how heterogeneity in the treatment effect is systematically related to observable characteristics. 
# From this results we saw that variables such as: religious adherence, women labor force participation and domestic violence were the main drivers of heterogeneity across 
# results. By later plotting the distribution of CATEs for these variables we further confirmed that, on the one hand, Religious Adherence has a strong negative effect on the impact of the reform,
# while Women Labor Force Participation and Domestic Violence present weaker relationships with the magnitude of the treatement effect in the divorce rates across counties. 

# The Targeting Operato Characteristics (TOC) confirms that not only heterogeneity is present but that is also economically meaningful, since the AUTOC is positive and 
# statistically significant. Additionally, the TOC reveals that the counties with a higher predicted CATEs are those with a higher average treatement effect, which is in line 
# with out analysis and further confirms the presence and relavence of heterogeneity. Indeed, an AUTOC of zero would indicate no heterogeneity. 
# The positive and significant estimate here is evidence that treatment effects differ across counties, 
# and that the covariates identified in the BLP — particularly religious adherence and women's labor force participation — are driving part of this variation

# Finally, Treatment timing may be endogenous: variables like religiosity or female labor supply could affect both reform adoption and divorce rates, violating unconfoundedness.
# Hence, estimated heterogeneity may reflect selection rather than true treatment effects, and results should be interpreted with caution despite some support for parallel trends.
# Building on Friedberg's results, the estimated effects may reflect underlying pre-existing trends rather than true treatment effects, with variables like religiosity or female labor supply capturing residual confounding instead of genuine heterogeneity.
# Building on Wolfers, slow-moving demographic variables may reflect true heterogeneity rather than confounding once dynamics are properly modeled, but our simpler design leaves open the possibility that some selection bias still affects the estimates.
# Overall: Wolfers' results moderately strengthen the credibility of our heterogeneity findings, but do not fully resolve the concern given the differences in research design.

## POINT D: 

# A model is honest” if it does not use the same information for selecting the model structure (grow a tree) as for estimation given a model structure.
# In other words, and honest estimation is one that splits the training sample in two parts: the "training observations" for the model selection (which are those used 
# to construct a tree), and the "estimating observations" that are those used for estimating the treatment effect within each leaf. 

# This procedure is important for our estimation of CATE since, without it the sample used for structuring the model and the one for estimating the treatment would be the 
# same which would probably lead to over-fitting issues and invalidates the asymptotic normality that underpins confidence intervals, which says that if the sample size is large enough 
# the CATE estimates converge asymptotically to a normal distribution. 

#rerun the regression, without using honest trees (in the other honesty is used by default): 
cf_dishonest <- causal_forest(X, Y, W, num.trees = 2000, honesty = FALSE , seed = 123)

#compare ATE: 
average_treatment_effect(cf) 
average_treatment_effect(cf_dishonest)

# The ATE are almost identical for both honest and dishonest estimation: in fact honesty mainly matters for CATE estimation, not for ATE. Since for CATE, using the same data for both
# splitting the data and estimating the treatment effect would lead to over-fitting. While ATE is less sensoble to over-fitting. 

#plot CATE (honest vs. dishonest)
cate_h <- predict(cf)$predictions
cate_d <- predict(cf_dishonest)$predictions
plot(cate_h, cate_d, xlab = "Honest CATE", ylab = "Dishonest CATE") 
abline(0, 1, col = "red", lty = 2)


# This scatter plot compares the estimated CATE with and without honesty. The two sets seem to be positive correlated, meaning that the counties that present a higher treatment effect 
# with honest estimation also present a high treatment effect for dishonest estimation. 
# Still, the dishonest CATE are more widely spread (estimates go from -1.5 to +1.5, while estimates for honest causal forest range roughly between -0.4 to 0.6). The explenation behind this pattern 
# is that the dishonest forest inflates the heterogeneity effect on treatment, thus the magintude of the CATE estimates is greater compared to the honest estimation ones. 