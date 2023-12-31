#' @title Find and integrate target features in each ROI
#' 
#' @description For each ROI, fit a curve and integrate the largest feature in
#' the box. Each entry in \code{ROIsDataPoints} must match the corresponding row
#' in \code{ROI}. The curve shape to employ for fitting can be changed with
#' \code{curveModel} while fitting parameters can be changed with \code{params}
#' (list with one param per ROI window). \code{rtMin} and \code{rtMax} are
#' established at 0.5% of apex intensity using a moving window from the apex
#' outward (the window is the ROI width); if after 8 iterations \code{rtMin} or
#' \code{rtMax} is not found, NA is returned and the peak fit rejected.
#' \code{peakArea} is calculated from \code{rtMin} to \code{rtMax}.
#' \code{peakAreaRaw} is calculated from \code{rtMin} to \code{rtMax} but
#' using the raw data points instead of the modelled line-shape.
#' \code{mz} is the weighted (by intensity)
#' average mz of datapoints falling into the \code{rtMin} to \code{rtMax}
#' range, \code{mzMin} and \code{mzMax} are the
#' minimum and maxmimum mass in these range. If \code{rtMin} or \code{rtMax}
#' falls outside of ROI (extracted scans), \code{mzMin} or \code{mzMax} are
#' returned as the input ROI limits and \code{mz} is an approximation on the
#' datapoints available (if no scan of the ROI fall between rtMin/rtMax, mz
#' would be NA, the peak is rejected). If any of the two following ratio are
#' superior to \code{maxApexResidualRatio}, the fit is rejected: 1) ratio of fit
#' residuals at the apex (predicted apex fit intensity vs measured apex
#' intensity: fit overshoots the apex), 2) ratio of predicted apex fit intensity
#' vs maximum measured peak intensity (fit misses the real apex in the peak).
#'
#' @param ROIsDataPoints (list) A list (one entry per ROI window) of data.frame
#' with signal as row and retention time ('rt'), mass ('mz') and intensity
#' ('int) as columns. Must match each row of ROI.
#' @param ROI (data.frame) A data.frame of compounds to target as rows. Columns:
#' \code{rtMin} (float in seconds), \code{rtMax} (float in seconds),
#' \code{mzMin} (float), \code{mzMax} (float)
#' @param curveModel (str) Name of the curve model to fit (currently
#' \code{skewedGaussian} and \code{emgGaussian})
#' @param params (list or str) Either 'guess' for automated parametrisation or
#' list (one per ROI windows) of 'guess' or list of curve fit parameters
#' @param sampling (int) Number of points to employ when subsampling the
#' fittedCurve (rt, rtMin, rtMax, integral calculation)
#' @param maxApexResidualRatio (float) Ratio of maximum allowed fit residual at
#' the peak apex, compared to the fit max intensity. (e.g. 0.2 for a maximum
#' residual of 20\% of apex intensity)
#' @param verbose (bool) If TRUE message the time taken and number of features
#' found
#' @param ... Passes arguments to \code{fitCurve} to alter peak fitting
#' (\code{params})
#'
#' @return A list: \code{list()$peakTable} (\emph{data.frame}) with targeted
#' features as rows and peak measures as columns (see Details),
#' \code{list()$curveFit} (\emph{list}) a list of \code{peakPantheR_curveFit} or
#' NA for each ROI.
#'
#' \subsection{Details:}{
#' The returned \code{data.frame} is structured as follow:
#' \tabular{ll}{
#' found \tab was the peak found\cr
#' rt \tab retention time of peak apex (sec)\cr
#' rtMin \tab leading edge of peak retention time (sec) determined at 0.5\% of
#' apex intensity\cr
#' rtMax \tab trailing edge of peak retention time (sec) determined at 0.5\% of
#' apex intensity\cr
#' mz \tab weighted (by intensity) mean of peak m/z across scans\cr
#' mzMin \tab m/z peak minimum (between rtMin, rtMax)\cr
#' mzMax \tab m/z peak maximum (between rtMin, rtMax)\cr
#' peakArea \tab integrated peak area\cr
#' peakAreaRaw \tab integrated peak area from raw data points\cr
#' maxIntMeasured \tab maximum peak intensity in raw data\cr
#' maxIntPredicted \tab maximum peak intensity based on curve fit (at apex)\cr
#' }
#' }
#'
#' @details
#' ## Examples cannot be computed as the function is not exported:
#' ## Load data
#' library(faahKO)
#' library(MSnbase)
#' netcdfFilePath <- system.file('cdf/KO/ko15.CDF', package = 'faahKO')
#' raw_data <- MSnbase::readMSData(netcdfFilePath,centroided=TRUE,mode='onDisk')
#'
#' ## targetFeatTable
#' targetFeatTable <- data.frame(matrix(vector(), 2, 8, dimnames=list(c(),
#'                         c('cpdID','cpdName','rtMin','rt','rtMax','mzMin',
#'                         'mz','mzMax'))), stringsAsFactors=FALSE)
#' targetFeatTable[1,] <- c('ID-1', 'Cpd 1', 3310., 3344.888, 3390., 522.194778,
#'                         522.2, 522.205222)
#' targetFeatTable[2,] <- c('ID-2', 'Cpd 2', 3280., 3385.577, 3440., 496.195038,
#'                         496.2, 496.204962)
#' targetFeatTable[,3:8] <- vapply(targetFeatTable[,3:8], as.numeric,
#'                         FUN.VALUE=numeric(2))
#'
#' ROIsPt <- extractSignalRawData(raw_data,
#'                                 rt=targetFeatTable[,c('rtMin','rtMax')],
#'                                 mz=targetFeatTable[,c('mzMin','mzMax')],
#'                                 verbose=TRUE)
#' # Reading data from 2 windows
#'
#' foundPeaks <- findTargetFeatures(ROIsPt, targetFeatTable, verbose=TRUE)
#' # Warning: rtMin/rtMax outside of ROI; datapoints cannot be used for
#' # mzMin/mzMax calculation,
#' # approximate mz and returning ROI$mzMin and ROI$mzMax for ROI #1
#' # Found 2/2 features in 0.07 secs
#' 
#' foundPeaks
#' # $peakTable
#' #   found    rtMin       rt    rtMax    mzMin    mz    mzMax peakArea
#' # 1  TRUE 3309.759 3346.828 3385.410 522.1948 522.2 522.2052 26133727
#' # 2  TRUE 3345.377 3386.529 3428.279 496.2000 496.2 496.2000 35472141
#' #   peakAreaRaw maxIntMeasured maxIntPredicted
#' # 1    26071378         889280        901015.8
#' # 2    36498367        1128960       1113576.7
#' #
#' # $curveFit
#' # $curveFit[[1]]
#' # $amplitude
#' # [1] 162404.8
#' # 
#' # $center
#' # [1] 3341.888
#' # 
#' # $sigma
#' # [1] 0.07878613
#' # 
#' # $gamma
#' # [1] 0.00183361
#' # 
#' # $fitStatus
#' # [1] 2
#' # 
#' # $curveModel
#' # [1] 'skewedGaussian'
#' # 
#' # attr(,'class')
#' # [1] 'peakPantheR_curveFit'
#' # 
#' # $curveFit[[2]]
#' # $amplitude
#' # [1] 199249.1
#' # 
#' # $center
#' # [1] 3382.577
#' # 
#' # $sigma
#' # [1] 0.07490442
#' # 
#' # $gamma
#' # [1] 0.00114719
#' # 
#' # $fitStatus
#' # [1] 2
#' # 
#' # $curveModel
#' # [1] 'skewedGaussian'
#' # 
#' # attr(,'class')
#' # [1] 'peakPantheR_curveFit'
findTargetFeatures  <- function(ROIsDataPoints, ROI,
                                curveModel = "skewedGaussian", params = "guess",
                                sampling = 250, maxApexResidualRatio = 0.2,
                                verbose = FALSE,...) {
    stime <- Sys.time()
    nROI <- nrow(ROI)

    # Check inputs (ROIsDataPoints match ROI, inputs, length)
    findTargetFeatures_checkInput(ROIsDataPoints, ROI, params)
    
    # Init output
    opt <- findTargetFeatures_initOutput(ROI, params, verbose)
    outTable <- opt$outTable; outCurveFit <- opt$outCurveFit
    useParams <- opt$useParams
    
    # Fit each ROI
    for (i in seq_len(nROI)) {
        fitRes <- findTargetFeatures_fitFeature(i,ROI,ROIsDataPoints,curveModel,
                                                useParams, params, sampling,
                                                maxApexResidualRatio, verbose,
                                                ...)
        # NULL if no fit, pass to next ROI
        if (is.null(fitRes)) {
            next
        } else {
            # Set all values: curveFit
            outCurveFit[[i]]            <- fitRes$fittedCurve
            # peaktable
            outTable$found[i]           <- TRUE
            outTable$rt[i]              <- fitRes$rt
            outTable$rtMin[i]           <- fitRes$rtMin
            outTable$rtMax[i]           <- fitRes$rtMax
            outTable$mz[i]              <- fitRes$mz
            outTable$mzMin[i]           <- fitRes$mzMin
            outTable$mzMax[i]           <- fitRes$mzMax
            outTable$peakArea[i]        <- fitRes$peakArea
            outTable$peakAreaRaw[i]     <- fitRes$peakAreaRaw
            outTable$maxIntMeasured[i]  <- fitRes$maxIntMeasured
            outTable$maxIntPredicted[i] <- fitRes$maxIntPredicted
        }
    }

    # Output
    etime <- Sys.time()
    if (verbose) {
        message("Found ", sum(outTable$found), "/", nROI, " features in ",
                round(as.double(difftime(etime, stime)), 2), " ",
                units(difftime(etime, stime))) }
    return(list(peakTable = outTable, curveFit = outCurveFit))
}


# -----------------------------------------------------------------------------
# findTargetFeatures helper functions

## Check inputs (ROIsDataPoints match ROI, inputs, length)
findTargetFeatures_checkInput <- function(ROIsDataPoints, ROI, params) {
    nROI <- nrow(ROI)
    # ROIsDataPoints match ROI
    if (length(ROIsDataPoints) != nROI) {
        stop('Check input, number of ROIsDataPoints entries must match ',
            'the number of rows of ROI')
    }
    # Check all data points fall into the corresponding ROI
    for (r in seq_len(nROI)) {
        if (!all((ROIsDataPoints[[r]]$rt >= ROI[r, c("rtMin")]) &
            (ROIsDataPoints[[r]]$rt <= ROI[r, c("rtMax")]))) {
            stop("Check input not all datapoints for window #", r,
                " are into the corresponding ROI (rt)")
        }
        if (!all((ROIsDataPoints[[r]]$mz >= ROI[r, c("mzMin")]) &
            (ROIsDataPoints[[r]]$mz <= ROI[r, c("mzMax")]))) {
            stop("Check input not all datapoints for window #", r,
                " are into the corresponding ROI (mz)")
        }
    }
    # Check params input
    if (!(is.character(params) | is.list(params))) {
        stop("Check input, \"params\" must be \"guess\" or list")}
    # params is 'guess' if character
    if (is.character(params)) {
        if (params != "guess") {
            stop("Check input, \"params\" must be \"guess\" if not list")}
    }
    # length if params is list
    if (is.list(params)) {
        if (length(params) != nROI) {
            stop('Check input, number of parameters must match number ',
                'of rows of ROI')}
    }
}


## Init output
findTargetFeatures_initOutput <- function(ROI, params, verbose) {
    nROI <- nrow(ROI)

    outTable <- data.frame(matrix(vector(), nROI, 11, dimnames = list(c(),
        c("found", "rtMin", "rt", "rtMax", "mzMin", "mz", "mzMax", "peakArea",
        "peakAreaRaw", "maxIntMeasured", "maxIntPredicted"))),
    stringsAsFactors = FALSE)
    outTable$found  <- rep(FALSE, nROI)  # set found to FALSE
    outCurveFit     <- rep(list(NA), nROI)

    # use input params or guess
    if (any(params != "guess")) {
        useParams <- TRUE
        if (verbose) {
            message("Curve fitting parameters passed as input employed")}
    } else {
        useParams <- FALSE
    }
    return(list(outTable=outTable, outCurveFit=outCurveFit,
                useParams=useParams))
}


## Fit single feature
# fit feature i, returns NULL to pass to the next feature (empty df row
# already initialised)
findTargetFeatures_fitFeature <- function(i, ROI, ROIsDataPoints, curveModel,
                                            useParams, params, sampling,
                                            maxApexResidualRatio, verbose, ...){
    # set params for fitting
    new_params <- "guess"
    if (useParams) { new_params <- params[[i]] }
    # extract EIC to fit
    tmp_EIC <- generateIonChromatogram(ROIDataPoint = ROIsDataPoints[[i]],
                                        aggregationFunction = "sum")

    # fit curve to EIC, in case of failure move to next window
    fittedCurve <- findTargetFeatures_fitcurve(i, tmp_EIC, curveModel,
                                                new_params, verbose, ...)
    if (is.null(fittedCurve)){ return(NULL) }

    # find rt, rtMin, rtMax and maxIntPredicted for a fitted curve
    rtRes <- findTargetFeatures_findRTproperties(i, ROI, tmp_EIC, fittedCurve,
                                                sampling, verbose)
    if (is.null(rtRes)){ return(NULL) }
    rt <- rtRes$rt; rtMin <- rtRes$rtMin; rtMax <- rtRes$rtMax
    maxIntPredicted <- rtRes$maxIntPredicted

    # maxIntMeasured (max raw data intensity; 0 in case of no scans)
    maxIntMeasured <- max(0, tmp_EIC$int[(tmp_EIC$rt < rtMax) &
                            (tmp_EIC$rt > rtMin)])

    # find mz, mzMin and mzMax
    mzRes <- findTargetFeatures_findMZ(i,ROI,rtMin,rtMax,ROIsDataPoints,verbose)
    if (is.null(mzRes)){ # move to next window
        return(NULL) }
    mz <- mzRes$mz; mzMin <- mzRes$mzMin; mzMax <- mzRes$mzMax

    # integrate curve
    peakArea <- findTargetFeatures_integCurve(fittedCurve,rtMin,rtMax,sampling)
    # integrate curve - raw datapoints
    rtBound <- (tmp_EIC$rt < rtMax) & (tmp_EIC$rt > rtMin)
    peakAreaRaw <- pracma::trapz(x=tmp_EIC$rt[rtBound], y=tmp_EIC$int[rtBound])

    # Check quality of fit (residuals at apex,and max predicted to max measured)
    qcRes <- findTargetFeatures_fitQuality(i, tmp_EIC, rt, maxIntPredicted,
                                maxIntMeasured, maxApexResidualRatio, verbose)
    if (!qcRes) { return(NULL) }

    return(list(fittedCurve=fittedCurve, rt=rt, rtMin=as.numeric(rtMin),
                rtMax=as.numeric(rtMax), mz=mz, mzMin=mzMin, mzMax=mzMax,
                peakArea=peakArea, peakAreaRaw=peakAreaRaw,
                maxIntMeasured=maxIntMeasured, maxIntPredicted=maxIntPredicted))
}
## Other EIC extraction ----
# resample to a standardised grid of size the maximum between
# 2*sampling and raw number of data points (double sampling used for
# integration)
# rawData_EIC <- generateIonChromatogram(ROIDataPoint=
# ROIsDataPoints[[i]], aggregationFunction='sum')
# tmp_gridMin <- min(rawData_EIC$rt)
# tmp_gridMax <- max(rawData_EIC$rt)
# tmp_gridSampling <- max(2*sampling, dim(rawData_EIC)[1])
# grid_rt_EIC <- seq(from=tmp_gridMin, to=tmp_gridMax,
# by=((tmp_gridMax-tmp_gridMin)/(tmp_gridSampling-1)))
# raw_approx_fun <- stats::approxfun(x=rawData_EIC$rt,
#                                      y=rawData_EIC$int)
# tmp_EIC <- data.frame(rt=grid_rt_EIC,
#                          int=raw_approx_fun(grid_rt_EIC))


## fit curve to EIC
findTargetFeatures_fitcurve <- function(i, tmp_EIC, curveModel,
                                            new_params, verbose, ...){
    # fit curve to EIC
    # return fittedCurve. If failure return NULL to move to next window
    fittedCurve <- tryCatch({
        ## try
        fittedCurve <- fitCurve(x = tmp_EIC$rt, y = tmp_EIC$int,
                                curveModel = curveModel, params = new_params,
                                ...)
    }, error = function(cond) {
        ## catch
        return(NA)
    })
    # catch fit failure
    if (all(is.na(fittedCurve))) {
        if (verbose) {
            message("Fit of ROI #", i, " is unsuccessful (try err)")}
        # indicate failure
        return(NULL)
    }
    # discard fit if nls.lm fit status indicates unsuccessful completion
    if ((fittedCurve$fitStatus == 0) | (fittedCurve$fitStatus == 5) |
        (fittedCurve$fitStatus == -1)) {
        if (verbose) {
            message("Fit of ROI #", i, " is unsuccessful (fit status)")}
        # indicate failure
        return(NULL)
    }
    return(fittedCurve)
}


## find rt, rtMin, rtMax and maxIntPredicted for a fitted curve
findTargetFeatures_findRTproperties <- function(i, ROI, tmp_EIC, fittedCurve,
                                                sampling, verbose){
    # If failure return NULL to move to next window

    # rt (search on same bounds as peak fit +/-3s)
    rt_EICmax   <- tmp_EIC$rt[which.max(tmp_EIC$int)]
    grid_rt     <- seq(from = rt_EICmax - 3, to = rt_EICmax + 3,
                        by = (6/(sampling - 1)))
    close_apex_int  <- predictCurve(fittedCurve, x = grid_rt)
    rt              <- grid_rt[which.max(close_apex_int)]

    # maxIntPredicted (fit apex intensity)
    maxIntPredicted <- predictCurve(fittedCurve = fittedCurve, x = rt)

    # rtMin, rtMax (look for 0.5% from max int, by rolling away from apex
    # until match or too many iterations)
    rtMin <- findTargetFeatures_findRTMinMax(min=TRUE, i, ROI, fittedCurve, rt,
                                            maxIntPredicted, sampling, verbose)
    rtMax <- findTargetFeatures_findRTMinMax(min=FALSE, i, ROI, fittedCurve, rt,
                                            maxIntPredicted, sampling, verbose)

    # if rtMin or rtMax cannot be determined the fit is not successful
    if (is.na(rtMin) | is.na(rtMax)) {
        message("Fit of ROI #", i,
                " is unsuccessful (cannot determine rtMin/rtMax)")
        # indicate failure
        return(NULL)
    }
    return(list(rt = rt, rtMin = rtMin, rtMax = rtMax,
                maxIntPredicted = maxIntPredicted))
}

## find rtMin or rtMax for a fitted curve
findTargetFeatures_findRTMinMax <- function(min, i, ROI, fittedCurve, rt,
                                        maxIntPredicted, sampling, verbose) {
    # rtMin/Max (look for 0.5% from max int, by rolling away from apex
    # until match or too many iterations)
    peakLim_int <- 0.005 * maxIntPredicted
    deltaRt     <- ROI$rtMax[i] - ROI$rtMin[i]

    rtMinMax    <- as.numeric(NA)
    cntr        <- 0
    if (min) { boxMin <- rt } else { boxMax <- rt } # Up / Down slope init

    # search rtMin/Max
    while (is.na(rtMinMax) & cntr <= 8) {
        cntr <- cntr + 1

        if (min) {
            # box moves earlier in rt each time
            boxMax  <- boxMin
            boxMin  <- boxMax - deltaRt
            grid_rt <- seq(from = boxMax, to = boxMin,
                            by = ((boxMin - boxMax)/(sampling - 1)))
            # reverse order for up slope
        } else {
            # box moves later in rt each time
            boxMin  <- boxMax
            boxMax  <- boxMin + deltaRt
            grid_rt <- seq(from = boxMin, to = boxMax,
                            by = ((boxMax - boxMin)/(sampling - 1)))
        }

        slope_int <- predictCurve(fittedCurve, x = grid_rt)
        cutoff_pt <- match(-1, sign(slope_int - peakLim_int))
            # pos of 1st point past cutoff
        if (is.na(cutoff_pt)) {
            rtMinMax <- as.numeric(NA)
            next
        }
        key_pt  <- c(cutoff_pt - 1, cutoff_pt)
            # points left and right from rtMin/Max
        rtMinMax <- stats::approx(x = slope_int[key_pt], y = grid_rt[key_pt],
                                xout = peakLim_int)$y
            # linear interpolation of exact rt
    }
    if (is.na(rtMinMax) & verbose) {
        if (min) { txt <- 'rtMin' } else { txt <- 'rtMax' }
        message("War","ning: ", txt, " cannot be determined for ROI #", i)}

    return(rtMinMax)
}

## find mz, mzMin and mzMax at a given rtMin rtMax
# If failure return NULL to move to next window
findTargetFeatures_findMZ <- function(i, ROI, rtMin, rtMax, ROIsDataPoints,
                                        verbose){
    # mz, mzMin, mzMax: if rtMin, rtMax are outside of ROI, we cannot calculate
    # mzMin, mzMax and mz precisely: default to ROI$mzMIn, ROI$mzMax as a safe
    # choice, and approximate mz
    mzMin <- ROI$mzMin[i]; mzMax <- ROI$mzMax[i]; ROIData <- ROIsDataPoints[[i]]
    isValid <- TRUE

    # deal with rtMin rtMax outside of ROI (warning)
    if ((rtMin < ROI$rtMin[i]) | (rtMax > ROI$rtMax[i])) {
        isValid <- FALSE
        if (verbose) {
            message('War','ning: rtMin/rtMax outside of ROI; datapoints ',
                    'cannot be used for mzMin/mzMax calculation, ',
                    'approximate mz and returning ROI$mzMin and ROI$mzMax ',
                    'for ROI #', i)
    }}

    # subset datapoints mz to rtMin/rtMax range
    tmpPt <- ROIData[(ROIData$rt > rtMin) & (ROIData$rt < rtMax), ]

    # rtMin rtMax range can be used for mzMin mzMax calculation
    # (else init to ROI mzMin/Max)
    if (isValid) {
        mzMin <- min(tmpPt$mz); mzMax <- max(tmpPt$mz)
    }

    # calculate mz (might be an approx)
    # (weighted average of total intensity across all rt for each unique mz)
    mzRange             <- unique(tmpPt$mz)
    mzTotalIntensity    <- vapply(mzRange, function(x) {
        sum(tmpPt$int[tmpPt$mz == x])}, FUN.VALUE = numeric(1))
    if (length(mzTotalIntensity) > 0) {
        # make sure weighted.mean doesn't crash if no scan match
        mz <- stats::weighted.mean(mzRange, mzTotalIntensity)
    } else {
        mz <- NA }

    # if mz, mzMin or mzMax cannot be determined the fit is not successful
    # (mzMin/mzMax default to ROI)
    if (is.na(mz) | is.na(mzMin) | is.na(mzMax)) {
        if (verbose) {
            message("Fit of ROI #", i,
                    " is unsuccessful (cannot determine mz/mzMin/mzMax)")
        }
        # indicate failure
        return(NULL) }
    return(list(mz=mz, mzMin=mzMin, mzMax=mzMax))
}

## integrate a fittedCurve on the rtMin rtMax range
findTargetFeatures_integCurve <- function(fittedCurve, rtMin, rtMax, sampling){
    ## integrate curve
    #       __a__
    #      /|     \
    #    /  h      \
    #  /____|__b____\
    # \     |      /
    #  \    h     /
    #   \___|__c_/
    # Area  = (a+b)/2 * h + (b+c)/2 * h
    #       = (a+2b+c)/2 * h
    h           <- (rtMax - rtMin)/(sampling - 1)
    grid_rt     <- seq(from = rtMin, to = rtMax, by = h)
    val_int     <- predictCurve(fittedCurve, x = grid_rt)
    peakArea    <- pracma::trapz(x=grid_rt, y=val_int)
}


## ! Unused filtering based on residuals ! ----
# @param maxResidualRatio (float) Ratio of maximum allowed residual
# area compared to the fit area. (e.g. 0.20 for a maximum residual area
# of 20% of fit area)
## Check quality of fit (residual area compared to peakArea) use the
## common range of ROI(raw data) and curve fit
# tmpRtMin <- max(rtMin, min(tmpROIData$rt))
# tmpRtMax <- min(rtMax, max(tmpROIData$rt))
# h_res <- (tmpRtMax-tmpRtMin)/(sampling-1)
# grid_rt_res <- seq(from=tmpRtMin, to=tmpRtMax, by=h_res)
## project raw data approx and curve fit on common grid
# raw_approx_fun <- stats::approxfun(x=tmp_EIC$rt, y=tmp_EIC$int)
# raw_proj <- raw_approx_fun(grid_rt_res)
# fit_proj <- predictCurve(fittedCurve, x=grid_rt_res)
## calculate residuals area on section considered
# fit_residuals <- abs(raw_proj - fit_proj)
# dist_residuals <- sum( c(fit_residuals,
#                       fit_residuals[2:(sampling-1)]) )/2
# area_residuals <- dist_residuals * h_res
## calculate peak area on section considered
# dist_subfit <- sum( c(fit_proj, fit_proj[2:(sampling-1)]) )/2
# area_subfit <- dist_subfit * h_res
## compare residual area to fit area
# if (area_residuals > (area_subfit * maxResidualRatio)) {
#   if (verbose) {message('Fit of ROI #', i,
#                           ' is unsuccessful (fit residuals is ',
#                           round(area_residuals / area_subfit, 2),
#                           ' of peak area)')}
# # move to next window (empty df row was already initialised) next
# }

## Quality of fit QC check, TRUE if pass QC check
findTargetFeatures_fitQuality <- function(i, tmp_EIC, rt, maxIntPredicted,
                                maxIntMeasured, maxApexResidualRatio, verbose) {
    # Check quality of fit (residuals at apex,and max predicted to max measured)
    # maxIntMeasured: peak max value in raw data maxIntPredicted: fit apex value
    # IntRawApex: raw data apex value
    raw_approx_fun  <- stats::approxfun(x = tmp_EIC$rt, y = tmp_EIC$int)
    IntRawApex      <- raw_approx_fun(rt)
    if (is.na(IntRawApex)) {IntRawApex <- 0}
    # residual at apex
    apex_residuals  <- abs(maxIntPredicted - maxIntMeasured)
    # residual between maximums (raw vs fit)
    max_residuals   <- abs(maxIntPredicted - IntRawApex)
    # compare residuals to max fit intensity
    if (((apex_residuals/maxIntPredicted) > maxApexResidualRatio) |
        ((max_residuals/maxIntPredicted) > maxApexResidualRatio)) {
        if (verbose) {
            message("Fit of ROI #",i," is unsuccessful (apex residuals is ",
                    round(apex_residuals/maxIntPredicted, 2),
                    " of max fit intensity, max intensity residuals is ",
                    round(max_residuals/maxIntPredicted, 2),
                    " of max fit intensity)")
        }
        return(FALSE)
    }
    return(TRUE)
}

## integrate a fittedCurve on the rtMin rtMax range
# Previous version without pracma

#findTargetFeatures_integCurve <- function(fittedCurve, rtMin, rtMax, sampling){
#    ## integrate curve
#    #       __a__
    #      /|     \
    #    /  h      \
    #  /____|__b____\
    # \     |      /
    #  \    h     /
    #   \___|__c_/
    # Area  = (a+b)/2 * h + (b+c)/2 * h
    #       = (a+2b+c)/2 * h
#    h           <- (rtMax - rtMin)/(sampling - 1)
#    grid_rt     <- seq(from = rtMin, to = rtMax, by = h)
#    val_int     <- predictCurve(fittedCurve, x = grid_rt)
#    dist        <- sum(c(val_int, val_int[2:(sampling - 1)]))/2
#    peakArea    <- dist * h
#}