rm(list = ls(all = TRUE))
# setwd('C:/...')

# install.packages('abind')
library(abind)

# generates a homogeneous Poisson process with intensity lambda
simHPP &lt;- function(lambda, T, N) {
    # lambda: scalar, intensity of the Poisson process T: scalar, time horizon N: scalar, number of trajectories
    EN &lt;- rpois(N, lambda * T)
    y &lt;- matrix(T, nrow = 2 * max(EN) + 2, ncol = N) * matrix(1, nrow = 2 * max(EN) + 2, ncol = N)
    yy &lt;- abind(y, matrix(1, nrow = 2 * max(EN) + 2, ncol = N) * EN, along = 3)
    i = 1
    while (i &lt;= N) {
        if (EN[i] &gt; 0) {
            yy[1:(2 * EN[i] + 1), i, 1] &lt;- c(0, rep(sort(T * runif(EN[i])), each = 2))
        } else {
            yy[1, i, 1] = 0
        }
        yy[1:(2 * EN[i] + 2), i, 2] &lt;- c(0, floor((1:(2 * EN[i]))/2), EN[i])
        i = i + 1
    }
    return(yy)
}

# generates a non-homogeneous Poisson process with intensity lambda
simNHPP &lt;- function(lambda, parlambda, T, N) {
    # lambda: scalar, intensity function, sine function (lambda=0), linear function (lambda=1) or sine square function
    # (lambda=2) parlambda: n x 1 vector, parameters of the intensity function lambda (n=2 for lambda=1, n=3 otherwise) T:
    # scalar, time horizon N: scalar, number of trajectories
    a &lt;- parlambda[1]
    b &lt;- parlambda[2]
    if (lambda == 0) {
        c &lt;- parlambda[3]
        JM &lt;- simHPP(a + b, T, N)
    } else {
        if (lambda == 1) {
            JM &lt;- simHPP(a + b * T, T, N)
        } else {
            if (lambda == 3) {
                JM &lt;- simHPP(a + b * T, T, N)
            }
        }
    }
    rjm &lt;- nrow(JM)
    yy &lt;- abind(matrix(T, nrow = rjm, ncol = N), matrix(0, nrow = rjm, ncol = N), along = 3)
    i = 1
    maxEN = 0
    while (i &lt;= N) {
        pom &lt;- JM[, i, 1][JM[, i, 1] &lt; T]
        pom &lt;- pom[2 * (1:(length(pom)/2))]
        R &lt;- runif(NROW(pom))
        if (lambda == 0) {
            lambdat &lt;- (a + b * sin(2 * pi * (pom + c)))/(a + b)
        } else {
            if (lambda == 1) {
                lambdat &lt;- (a + b * pom)/(a + b * T)
            } else {
                if (lambda == 3) {
                  lambdat &lt;- (a + b * sin(2 * pi * (pom + c))^2)/(a + b)
                }
            }
        }
        pom &lt;- pom[R &lt; lambdat]
        EN &lt;- NROW(pom)
        maxEN &lt;- max(maxEN, EN)
        yy[1:(2 * EN + 1), i, 1] &lt;- c(0, rep(pom, each = 2))
        yy[2:(2 * EN), i, 2] &lt;- c(floor((1:(2 * EN - 1))/2))
        yy[(2 * EN + 1):rjm, i, 2] &lt;- matrix(EN, nrow = rjm - 2 * EN, ncol = 1)
        i = i + 1
    }
    yy &lt;- yy[1:(2 * maxEN + 2), , ]
    return(yy)
}

# linear intensity
set.seed(1)

y1 &lt;- simNHPP(1, c(1, 0), 10, 1)
y2 &lt;- simNHPP(1, c(1, 0.1), 10, 1)
y3 &lt;- simNHPP(1, c(1, 1), 10, 1)

plot(y1, type = "l", col = "green", ylim = c(0, 60), xlab = "t", ylab = "N(t)", cex.lab = 1.4, cex.axis = 1.4, lwd = 3, lty = 4)
lines(y2, col = "red", lwd = 3, lty = 5)
lines(y3, col = "blue", lwd = 3)

# sinusoidal intensity

y1 &lt;- simNHPP(0, c(10, 0, 1/4), 10, 1)
y2 &lt;- simNHPP(0, c(10, 1, 1/4), 10, 1)
y3 &lt;- simNHPP(0, c(10, 10, 1/4), 10, 1)

plot(y1, type = "l", col = "green", ylim = c(0, 100), xlab = "t", ylab = "N(t)", cex.lab = 1.4, cex.axis = 1.4, lwd = 3, lty = 4)
lines(y2, col = "red", lwd = 3, lty = 5)
lines(y3, col = "blue", lwd = 3)
