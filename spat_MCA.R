originalPar <- par(no.readonly = TRUE)
# The following examples only use two threads for parallel computing.
## 1D: regular locations
p <- q <- 10
n <- 100
x1 <- matrix(seq(-7, 7, length = p), nrow = p, ncol = 1)
x2 <- matrix(seq(-7, 7, length = q), nrow = q, ncol = 1)
u <- exp(-x1^2) / norm(exp(-x1^2), "F")
v <- exp(-(x2 - 2)^2) / norm(exp(-(x2 - 2)^2), "F")
Sigma <- array(0, c(p + q, p + q))
Sigma[1:p, 1:p] <- diag(p)
Sigma[(p + 1):(p + q), (p + 1):(p + q)] <- diag(p)
Sigma[1:p, (p + 1):(p + q)] <- u %*% t(v)
Sigma[(p + 1):(p + q), 1:p] <- t(Sigma[1:p, (p + 1):(p + q)])
noise <- MASS::mvrnorm(n, mu = rep(0, p + q), Sigma = 0.001 * diag(p + q))
Y <- MASS::mvrnorm(n, mu = rep(0, p + q), Sigma = Sigma) + noise
Y1 <- Y[, 1:p]
Y2 <- Y[, -(1:p)]
cv1 <- spatmca(x1, x2, Y1, Y2, num_cores = 2)

par(mfrow = c(2, 1))
plot(x1, cv1$Uestfn[, 1], type='l', main = "1st pattern for Y1")
plot(x1, cv1$Vestfn[, 1], type='l', main = "1st pattern for Y2")
## Avoid changing the global enviroment
par(originalPar)


# The following examples will be executed more than 5 secs or including other libraries.
## 1D: artificial irregular locations
rmLoc1 <- sample(1:p, 3)
rmLoc2 <- sample(1:q, 4)
x1Rm <- x1[-rmLoc1]
x2Rm <- x2[-rmLoc2]
Y1Rm <- Y1[, -rmLoc1]
Y2Rm <- Y2[, -rmLoc2]
x1New <- as.matrix(seq(-7, 7, length = 100))
x2New <- as.matrix(seq(-7, 7, length = 50))
cv2 <- spatmca(x1 = x1Rm,
               x2 = x2Rm,
               Y1 = Y1Rm,
               Y2 = Y2Rm,
               x1New = x1New,
               x2New = x2New)
par(mfrow = c(2, 1))
plot(x1New, cv2$Uestfn[,1], type='l', main = "1st pattern for Y1")
plot(x2New, cv2$Vestfn[,1], type='l', main = "1st pattern for Y2")
par(originalPar)

## 2D real data
##  Daily 8-hour ozone averages and maximum temperature obtained from 28 monitoring
##  sites of NewYork, USA. It is of interest to see the relationship between the ozone
##  and the temperature through the coupled patterns.

library(spTimer)
library(pracma)
library(fields)
library(maps)
data(NYdata)
NYsite <- unique(cbind(NYdata[, 1:3]))
date <- as.POSIXct(seq(as.Date("2006-07-01"), as.Date("2006-08-31"), by = 1))
cMAXTMP<- matrix(NYdata[,8], 62, 28)
oz <- matrix(NYdata[,7], 62, 28)
rmNa <- !colSums(is.na(oz))
temp <- detrend(matrix(cMAXTMP[, rmNa], nrow = nrow(cMAXTMP)), "linear")
ozone <- detrend(matrix(oz[, rmNa], nrow = nrow(oz)), "linear")
x1 <- NYsite[rmNa, 2:3]
cv <- spatmca(x1, x1, temp, ozone)
par(mfrow = c(2, 1))
quilt.plot(x1, cv$Uestfn[, 1],
           xlab = "longitude",
           ylab = "latitude",
           main = "1st spatial pattern for temperature")
map(database = "state", regions = "new york", add = TRUE)
quilt.plot(x1, cv$Vestfn[, 1],
           xlab = "longitude",
           ylab = "latitude",
           main = "1st spatial pattern for ozone")
map(database = "state", regions = "new york", add = TRUE)
par(originalPar)

### Time series for the coupled patterns
tstemp <- temp %*% cv$Uestfn[,1]
tsozone <- ozone %*% cv$Vestfn[,1]
corr <- cor(tstemp, tsozone)
plot(date, tstemp / sd(tstemp), type='l', main = "Time series", ylab = "", xlab = "month")
lines(date, tsozone/sd(tsozone),col=2)
legend("bottomleft", c("Temperature (standardized)", "Ozone (standardized)"), col = 1:2, lty = 1:1)
mtext(paste("Pearson's correlation = ", round(corr, 3)), 3)

newP <- 50
xLon <- seq(-80, -72, length = newP)
xLat <- seq(41, 45, length = newP)
xxNew <- as.matrix(expand.grid(x = xLon, y = xLat))
cvNew <- spatmca(x1 = x1,
                 x2 = x1,
                 Y1 = temp,
                 Y2 = ozone,
                 K = cv$Khat,
                 tau1u = cv$stau1u,
                 tau1v = cv$stau1v,
                 tau2u = cv$stau2u,
                 tau2v = cv$stau2v,
                 x1New = xxNew,
                 x2New = xxNew)
par(mfrow = c(2, 1))
quilt.plot(xxNew, cvNew$Uestfn[, 1],
           nx = newP,
           ny = newP,
           xlab = "longitude",
           ylab = "latitude",
           main = "1st spatial pattern for temperature")
map(database = "county", regions = "new york", add = TRUE)
map.text("state", regions = "new york", cex = 2, add = TRUE)
quilt.plot(xxNew, cvNew$Vestfn[, 1],
           nx = newP,
           ny = newP,
           xlab = "longitude",
           ylab = "latitude",
           main = "2nd spatial pattern for ozone")
map(database = "county", regions = "new york", add = TRUE)
map.text("state", regions = "new york", cex = 2, add = TRUE)
par(originalPar)

## 3D: regular locations
n <- 200
x <- y <- z <- as.matrix(seq(-7, 7, length = 8))
d <- expand.grid(x, y, z)
u3D <- v3D <- exp(-d[, 1]^2 - d[, 2]^2 -d[, 3]^2)
p <- q <- 8^3
Sigma3D <- array(0, c(p + q, p + q))
Sigma3D[1:p, 1:p] <- diag(p)
Sigma3D[(p + 1):(p + q), (p + 1):(p + q)] <- diag(p)
Sigma3D[1:p, (p + 1):(p + q)] <- u3D %*% t(v3D)
Sigma3D[(p + 1):(p + q), 1:p] <- t(Sigma3D[1:p, (p + 1):(p + q)])

noise3D <- MASS::mvrnorm(n, mu = rep(0, p + q), Sigma = 0.001 * diag(p + q))
Y3D <- MASS::mvrnorm(n, mu = rep(0, p + q), Sigma = Sigma3D) + noise3D
Y13D <- Y3D[, 1:p]
Y23D <- Y3D[, -(1:p)]
cv3D <- spatmca(d, d, Y13D, Y23D)

library(plot3D)
library(RColorBrewer)
cols <- colorRampPalette(brewer.pal(9, 'Blues'))(10)
isosurf3D(x, y, z,
          colvar = array(cv3D$Uestfn[, 1], c(8, 8, 8)),
          level = seq(min(cv3D$Uestfn[, 1]), max(cv3D$Uestfn[, 1]), length = 10),
          ticktype = "detailed",
          colkey = list(side = 1),
          col = cols,
          main = "1st estimated pattern for Y1")

isosurf3D(x, y, z,
          colvar = array(cv3D$Vestfn[, 1], c(8, 8, 8)),
          level = seq(min(cv3D$Vestfn[, 1]), max(cv3D$Vestfn[,1]), length = 10),
          ticktype = "detailed",
          colkey = list(side = 1),
          col = cols,
          main = "1st estimated pattern for Y2")
