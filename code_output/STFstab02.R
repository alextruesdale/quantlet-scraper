rm(list = ls(all = TRUE))
graphics.off()
# setwd('C:/...')

install.packages("fBasics")
install.packages("stabledist")
library(stabledist)
library(fBasics)

x &lt;- c(-50:50)/10

alpha &lt;- 1.2
beta &lt;- c(0, 0.5, 0.8, 1)

# stable pdfs
w1 &lt;- dstable(x, alpha, beta = beta[1], pm = 1)
w2 &lt;- dstable(x, alpha, beta = beta[2], pm = 1)
w3 &lt;- dstable(x, alpha, beta = beta[3], pm = 1)
w4 &lt;- dstable(x, alpha, beta = beta[4], pm = 1)

plot(x, w1, type = "l", main = "Dependence on beta", xlab = "x", ylab = "PDF(x)", cex.axis = 2, cex.lab = 1.4, cex.main = 2, 
    lwd = 3)
lines(x, w2, col = "red", lwd = 3, lty = 3)
lines(x, w3, col = "blue", lwd = 3, lty = 2)
lines(x, w4, col = "green", lwd = 3, lty = 5)

################################### 

# Gaussian, Cauchy, Levy pdfs
w5 &lt;- dnorm(x)

w6 &lt;- dcauchy(x, location = 0, scale = 1)

w7 &lt;- matrix(0, length(x))
for (i in 1:length(x)) {
    if (x[i] &gt; 0) {
        w7[i] &lt;- dstable(x[i], alpha = 0.5, beta = 1, pm = 1)
    }
}
dev.new()
plot(x, w7, type = "l", main = "Gaussian, Cauchy and Levy distributions", xlab = "x", ylab = "PDF(x)", cex.axis = 2, cex.lab = 1.4, 
    cex.main = 2, col = "blue", lwd = 3, lty = 2)
lines(x, w5, lwd = 3)
lines(x, w6, col = "red", lwd = 3, lty = 3)
