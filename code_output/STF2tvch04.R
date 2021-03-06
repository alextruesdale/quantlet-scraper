# Remove variables and close windows
rm(list = ls(all = TRUE))
graphics.off()

# Load library install.packages(c('aws', 'fGarch', 'igraph', 'Hmisc')) install.packages('igraph')
library(igraph)
library("fGarch")
library("igraph")
library("stats")
library("Hmisc")


# Kernel-NLS tvArch estimate
tvarch &lt;- function(p, X, t0, bn, lou = FALSE) {
    n &lt;- length(X)
    if (bn &lt; 1) 
        bn &lt;- bn * n
    t0 &lt;- min(max(bn + 1, t0), n - bn)
    if (lou) 
        wint &lt;- c((t0 - bn):(t0 - 1), (t0 + 1):(t0 + bn)) else wint &lt;- ((t0 - bn):(t0 + bn))
    
    if (p == 0) 
        return(list(coefs = mean(X[wint]^2), pred = mean(X[wint]^2)))
    
    matX &lt;- 1
    for (s in (1:p)) matX &lt;- cbind(matX, c(double(p), X[(p - s + 1):(n - s)]^2))
    mut &lt;- sum(X[wint]^2)/bn
    stdk &lt;- c(double(p - 1), running.mean(X^2, p))
    
    matXX &lt;- t(matX[wint - 1, ]) %*% (matX[wint - 1, ]/(mut + stdk[wint - 1])^2)/bn
    vecXX &lt;- t(matX[wint - 1, ]) %*% (X[wint]^2/(mut + stdk[wint - 1])^2)/bn
    at0 &lt;- solve(matXX) %*% vecXX
    
    if (lou) 
        pred &lt;- sum(at0 * matX[t0 - 1, ]) else pred &lt;- sum(at0 * matX[n, ])
    
    return(list(coefs = at0, pred = pred))
    
}

# bandwidth choice of tvARCH
tvband &lt;- function(p, X, per, pow = 2) {
    bn &lt;- c(seq(5 * (p + 1), 40, 5), seq(50, 100 + p * 30, 10))
    cv &lt;- double(length(bn))
    for (i in 1:length(bn)) {
        band &lt;- bn[i]
        for (t0 in (length(X) - per):length(X)) {
            res &lt;- tvarch(p, X[1:(t0 - 1)], t0, band)
            cv[i] &lt;- cv[i] + (abs(X[t0]^2 - res$pred))^pow
        }
    }
    
    return(bn[which.min(cv)])
}

data &lt;- read.delim2("SP1997-2005s.txt")


time &lt;- (1:length(data[, 1]))
dat0 &lt;- data[, 1] - c(mean(data[, 1]))
dat0 &lt;- dat0/sd(dat0)

pred &lt;- 0 * time - 1
bands &lt;- 0 * time - 1
p &lt;- 1
h &lt;- 1
coefs &lt;- matrix(0, NROW(pred), p + 1)
esterr &lt;- pred
ggarch &lt;- pred


band &lt;- 0
ghist &lt;- 250
sper &lt;- 70
for (i in 1076:2088) {
    if (band == 0) 
        band &lt;- tvband(p, dat0[(i - 500 - p * 60 - 66):(i - 1)], 66, pow = 1)
    print(c(i, band))
    bands[i] &lt;- band
    res &lt;- tvarch(p, dat0[(i - 500 - p * 60):(i - 1)], i, band)
    pred[i] &lt;- res$pred
    coefs[i, ] &lt;- res$coefs
    esterr[i] &lt;- sum(abs(pred[i] - dat0[i:(i + h - 1)]^2))
    
    gest &lt;- garchFit(~garch(1, 1), data = dat0[1:(i - 1)], trace = FALSE, include.mean = FALSE)
    ggarch[i] &lt;- sum(abs(predict(gest, n.ahead = h)$standardDeviation^2 - dat0[i:(i + h - 1)]^2))
    
    # set a fixed bandwidth (in days)?
    band &lt;- 0
}
lc &lt;- (pred)
timet &lt;- (time - 1078)/250 + 2001
dev.new()
plot(timet[pred &gt;= 0], dat0[pred &gt;= 0]^2, cex = 0.2, xaxp = c(2001, 2005, 4), xlab = "Time", ylab = "Squared log-returns")
lines(timet[pred &gt;= 0], pred[pred &gt;= 0])
minor.tick(4, 5)
readline("Save the plot...")

lc &lt;- lc[1:sum(pred &gt;= 0)]
time &lt;- time[1:sum(pred &gt;= 0)]

timet &lt;- timet[pred &gt;= 0]
errs &lt;- esterr[pred &gt;= 0]
ggarch &lt;- ggarch[pred &gt;= 0]
pred &lt;- pred[pred &gt;= 0]

lags &lt;- 21
dev.new()
plot(timet[lags:length(time)], running.mean(errs, lags)/running.mean(ggarch, lags), type = "l", xlab = "Time", ylab = "Ratio of L1 errors", 
    main = "TvARCH to global GARCH", xaxp = c(2001, 2005, 4))
abline(1, 0, lty = "dotted")
minor.tick(4, 5)
readline("Save the plot...")

print("Mean absolute forecast errors of tvARCH and GARCH:")

print("By year:")
for (ye in 1:4) print(c(mean(errs[(250 * (ye - 1) + 1):(250 * ye)]), mean(ggarch[(250 * (ye - 1) + 1):(250 * ye)])))
print("Total:")
print(c(mean(errs[1:1000]), mean(ggarch[1:1000])))
