rm(list = ls(all = TRUE))
graphics.off()

# install and load packages
libraries = c("fOptions")
lapply(libraries, function(x) if (!(x %in% installed.packages())) {
    install.packages(x)
})
lapply(libraries, library, quietly = TRUE, character.only = TRUE)

# parameter settings
S0     = 49         # Starting price
T      = 20/52      # Time to maturity
si     = 0.2        # Volatility
mu     = 0.13       # Drift
r      = 0.05       # Interest rate
K      = 50         # Strikeprice
NSteps = 2000       # Number of steps
NRepl  = 500        # Number of replications

NumObs = c(4, 5, 10, 20, 50, 100)

# Calculate the BS Price of the call
CallOpt = GBSOption(TypeFlag = "c", S = S0, X = K, Time = T, r = r, b = 0, sigma = si)
Call = attr(CallOpt, "price")

# Simulate the paths for the underlying stock
St        = matrix(0, NRepl, NSteps + 1)
St[, 1]   = rep(S0, NRepl)  #All paths start with S0
dt = T/NSteps  #Discretize the time to maturity into discrete time steps corresponding to NSteps in T
drift     = (mu - 0.5 * si^2) * dt  #Calculate the drift rate
diffusion = si * sqrt(dt)  #Calculate the diffusion process rate

for (i in seq(1, NRepl, 1)) {
    for (j in seq(1, NSteps, 1)) {
        St[i, j + 1] = St[i, j] * exp(drift + diffusion * rnorm(1, 0, 1))
    }
}

# Calculate the hedging cost at the specified observation times
ObsDensity      = NSteps/NumObs # size of time steps for the observations
DiscountFactors = exp(-r * seq(0, NSteps, 1) * dt)
Cost = matrix(0, NRepl, length(NumObs))
L = matrix(0, length(ObsDensity), length(ObsDensity))

for (m in seq(1, length(ObsDensity), 1)) {
    for (k in seq(1, NRepl, 1)) {
        CashFlows = matrix(0, NSteps + 1, 1)
        if (St[k, 1] &gt;= K) {
            Covered 		= 1
            CashFlows[1] 	= -St[k, 1]
        } else {
            Covered = 0
        }
        for (t in seq(1, (NSteps + 1), ObsDensity[m])) {
            if ((Covered == 1) &amp;&amp; (St[k, t] &lt; K)) {
                # Sell
                Covered = 0
                CashFlows[t] = St[k, t]
            }
            if ((Covered == 0) &amp;&amp; (St[k, t] &gt; K)) {
                # Buy
                Covered = 1
                CashFlows[t] = -St[k, t]
            }
        }
        if (St[k, NSteps + 1] &gt;= K) {
            # Option is exercised
            CashFlows[NSteps + 1] = CashFlows[NSteps + 1] + K
        }
        Cost[k, m] = -DiscountFactors %*% CashFlows
    }
    V      = apply(Cost, 2, var)
    L[m, ] = sqrt(V)/Call
}

print("Performance measure L:")
(X = colMeans(L))
