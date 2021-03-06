library(here)
library(RColorBrewer)
###############################################################################
# Load data
###############################################################################

CU_names <- read.csv("data/CentralCoastChum_CUs.csv")
CU_names <- as.character(CU_names[1:8,'CU_name']) #Ignore Wannock (no data)

datER <- read.csv("data/PSE_chumExploitationRate.csv")
datER <- subset(datER, is.element(datER$location, CU_names))

# Are all CUs in ER data?
CU_names[is.element(CU_names, datER$location) == FALSE]

###############################################################################
# Summarize data
###############################################################################
meanER <- mean(datER$datavalue)
sdER <- sd(datER$datavalue)

meanER_period1 <- mean(datER$datavalue[datER$year <= 1990])
meanER_period2 <- mean(datER$datavalue[datER$year > 1990])

# Perhaps makes more sense to look at sd among CUs within each year?
sdER2 <- mean(tapply(datER$datavalue, datER$year, sd))
# This is slightly lower than looking across all time.

###############################################################################
# Plot data
###############################################################################

par(mfrow=c(4,2), mar=c(2,2,1,1), oma=c(3,3,0,0))
for(i in 1:8){
	datER.i <- subset(datER, datER$location == CU_names[i])
	plot(datER.i$year, datER.i$datavalue, "o", xlim=c(1954, 2014), ylim=range(datER$datavalue, na.rm=TRUE), bty="n", xlab="", ylab="", las=1, main=CU_names[i])
}

# All together
colCU <- rainbow(8)#brewer.pal(8, "Accent")
par(mfrow=c(1,1), mar=c(4,4,2,1), oma=rep(0, 4))
plot(datER.i$year, datER.i$datavalue, "n", xlim=c(1954, 2014), ylim=range(datER$datavalue, na.rm=TRUE), bty="l", xlab="", ylab="", las=1)
for(i in 1:8){
	datER.i <- subset(datER, datER$location == CU_names[i])
	lines(datER.i$year, datER.i$datavalue, "o", col=colCU[i])
}
segments(x0=1954, x1=1990, y0=meanER_period1, y1=meanER_period1, lty=2, l)
segments(x0=1991, x1=2014, y0=meanER_period2, y1=meanER_period2, lty=2)
legend("topright", col=colCU, lwd=1, CU_names, ncol=2)

###############################################################################
# Representing with beta distribution
###############################################################################
betaPar <- function(mean, sd){
	beta1 <- (mean^2 - mean^3 - sd^2*mean)/(sd^2)
	beta2 <- (mean * (1 - mean)^2 - sd^2*(1 - mean))/(sd^2)
	return(c(beta1, beta2))
}

betaER <- betaPar(meanER, sdER2)
h <- rbeta(10^3, shape1 = betaER[1], shape2 = betaER[2])

hist(h, freq=FALSE)
lines(seq(0, 1, 0.01), dbeta(seq(0, 1, 0.01), shape1 = betaER[1], shape2 = betaER[2]))

mean(h)
sd(h)

###############################################################################
# Relationship between abundance and harvest rates
###############################################################################

datEsc <- read.csv("data/nccdbv2_NCCStreamEscapement.csv")
datAbund <- read.csv("data/PSE_chumSpawnerAbundanceAndTotalRunSize.csv")

datAbundLGL <- subset(datAbund, datAbund$parameter == "LGL counts")
datTotalRun <- subset(datAbund, datAbund$parameter == "Total run")



harvestPar <- data.frame(location = CU_names, hmax = rep(NA, length(CU_names)), d = rep(NA, length(CU_names)), m = rep(NA, length(CU_names))) 

dat.all <- data.frame(
	location = rep(NA, each = 61*length(CU_names)),
	year = rep(NA, 61*length(CU_names)), 
	harvestRate = rep(NA, 61*length(CU_names)), 
	totalRun = rep(NA, 61*length(CU_names)))
I <- 1
												 
for(i in c(1,3:8)){
	dat.i <- data.frame(
		y = subset(datER, datER$location == CU_names[i])$datavalue,
		x = subset(datTotalRun, datTotalRun$location == CU_names[i])$datavalue,
		esc = subset(datAbundLGL, datAbundLGL$location == CU_names[i])$datavalue,
		year = subset(datER, datER$location == CU_names[i])$year)

	dat.all$location[I:(I + dim(dat.i)[1] - 1)] <- CU_names[i]
	dat.all$year[I:(I+dim(dat.i)[1]-1)] <- dat.i$year
	dat.all$harvestRate[I:(I+dim(dat.i)[1]-1)] <- dat.i$y
	dat.all$totalRun[I:(I+dim(dat.i)[1]-1)] <- dat.i$x
	I <- I + dim(dat.i)[1]
}

# 	xmax <- ceiling(max(dat.i$x)*10^-5)*10^5
# 
# 	# Fit curve
# 	fit.i <- nls(
# 		y ~ hmax * (1 - exp(d * (m - x))),
# 		data = dat.i,
# 		start = list(hmax = 0.8, d = 1.2*10^-6, m = 10^5),
# 		lower = c(0, 0, 0),
# 		upper = c(1, Inf, 10^6),
# 		algorithm = "port")
# 	harvestPar[i,'hmax'] <- coefficients(fit.i)['hmax']
# 	harvestPar[i,'d'] <- coefficients(fit.i)['d']
# 	harvestPar[i,'m'] <- coefficients(fit.i)['m']
# 
# 	R.dummy <- seq(0, max(dat.i$x), length.out=200)
# 	h.dummy <- coefficients(fit.i)['hmax'] * (1 - exp(coefficients(fit.i)['d'] * (coefficients(fit.i)['m'] - R.dummy)))
# 
# 
# 	par(mfrow=c(2,1), mar=c(3,5,2,5), oma=c(1,0,0,0))
# 	bp <- barplot(rbind(dat.i$x - dat.i$esc, dat.i$esc), names.arg = NULL, las=1, col=c("#A8A6FF", "#FF0200"), yaxt="n", ylim=c(0, xmax), main=CU_names[i])
# 	axis(side=1, at=bp[match(seq(1960, 2010, 10), dat.i$year)], labels = seq(1960, 2010, 10))
# 
# 	xdist <- 100000
# 	while(length(seq(0, xmax, xdist)) > 8) xdist <- xdist * 2
# 	axis(side=2, at=seq(0, xmax, xdist), las=1, labels = formatC(seq(0, xmax/1000, xdist/1000), 0, format="f"))
# 
# 	mtext(side=2, "Escapement + harvest (1000s)", line=3)
# 	lines(bp, dat.i$y*xmax, lwd=1.5)
# 	axis(side=4, at=seq(0, 1, 0.2)*xmax, labels=seq(0, 1, 0.2), las=1)
# 	mtext(side=4, "Exploitation rate", line=3)
# 	mtext(side=3, line=1, adj=0, "a)")
# 
# 	plot(dat.i$x, dat.i$y, las=1, ylab="Exploitation rate", xlab="Escapement + harvest", bty="l", xlim=c(0, xmax), ylim=c(0,1), xaxs="i", yaxs="i", xaxt="n")
# 	axis(side=1, at=seq(0, xmax, xdist), las=1, labels = formatC(seq(0, xmax/1000, xdist/1000), 0, format="f"))
# 	mtext(side=1, "Escapement + harvest (1000s)", line=3)
# 
# 	mtext(side=3, line=1, adj=0, "b)")
# 
# 	lines(R.dummy, h.dummy, lwd=1.5)
# 	abline(h = coefficients(fit.i)['hmax'], lty=3)
# 	abline(v = coefficients(fit.i)['m'], lty=3)
# }
# 
# 

dat.all <- dat.all[1:(which(is.na(dat.all$location)==TRUE)[1]-1),]
dat.fit <- dat.all[dat.all$location != "Smith Inlet" & dat.all$location != "Rivers Inlet", ]

fit.all <- nls(
	y ~ hmax * (1 - exp(d * (m - x))), 
	data = data.frame(x=dat.fit$totalRun, y=dat.fit$harvestRate), 
	start = list(hmax = 0.8, d = 1.2*10^-6, m = 10^5), 
	lower = c(0, 0, 0), 
	upper = c(1, Inf, 10^6), 
	algorithm = "port")

R.dummy <- seq(0, 2*10^6, length.out = 200)
h.dummy <- pmax(0.05, coefficients(fit.all)['hmax'] * (1 - exp(coefficients(fit.all)['d'] * (coefficients(fit.all)['m'] - R.dummy))))

quartz(width = 4.5, height=2.5, pointsize = 10)
par(mfrow=c(1,1), mar=c(3.5,4,1,10), oma=c(0,0,0,0))
plot(dat.fit$totalRun,dat.fit$harvestRate, col = grey(0.7), las=1, xlab="", ylab = "Harvest rate", pch = as.numeric(as.factor(dat.fit$location)), xaxt="n", yaxt="n")
mtext(side=1, line=2.5, "Total return (millions)")
axis(side=1, at=seq(0, 1.5*10^6, 0.5*10^6), labels = c("0.0", "0.5", "1.0", "1.5"))
axis(side=2, at=c(0, 0.3, 0.6), las=1)
axis(side=2, at=coefficients(fit.all)['hmax'], labels=expression(paste(italic(h[MAX]))), las=1, cex.axis=0.8)#, col="dodgerblue3", col.axis="dodgerblue3")

lines(R.dummy, h.dummy, lwd=1.5)
# abline(h = coefficients(fit.all)['hmax'], lty=2, col="dodgerblue3")
abline(h = 0.60, lty=3)#, col="dodgerblue")
legend(2*10^6, 0.80, col=grey(0.7), pch = unique(as.numeric(as.factor(dat.fit$location))), legend= unique(dat.fit$location), xpd=NA, cex=0.8, pt.cex=1, bty="n")

legend(2*10^6, 0.35, lwd = c(1.5, 1), lty = c(1,3), legend = c("Harvest Control Rule", "High constant harvest"), cex=0.8, pt.cex=1, bty="n", xpd=NA)#col=c(1, "dodgerblue3", "dodgerblue"), 

#-----------------------------
# Plot residuals over time
#-----------------------------
dat.fit <- dat.all[dat.all$location != "Smith Inlet" & dat.all$location != "Rivers Inlet",]
res <- resid(fit.all)

par(mfrow=c(1,2), mar=c(4,4,2,1), oma=c(0,0,0,0))

plot(dat.fit$totalRun, dat.fit$harvestRate, col = grey(0.6), las=1, xlab="Total return (millions)", ylab = "Harvest rate", bty="l", pch = as.numeric(as.factor(dat.fit$location)), xaxt="n", yaxt="n")
axis(side=1, at=seq(0, 1.5*10^6, 0.5*10^6), labels = c("0.0", "0.5", "1.0", "1.5"))
axis(side=2, at=c(0, 0.3, 0.6), las=1)
axis(side=2, at=coefficients(fit.all)['hmax'], labels=expression(paste(italic(h[MAX]))), las=1, cex.axis=0.8, col="dodgerblue", col.axis="dodgerblue")
lines(R.dummy, h.dummy3, lwd=1.5)
mtext(side = 3, adj=0, line=0.5, "a) HCR fit")

plot(dat.fit$year, res, las=1, ylab="Residuals", xlab = "Return year", bty="l", pch = as.numeric(as.factor(dat.fit$location)), col=grey(0.6))
abline(h=0, lwd=1.5)
mtext(side = 3, adj=0, line=0.5, "b) Residuals from HCR fit")

