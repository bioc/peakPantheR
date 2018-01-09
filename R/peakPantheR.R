###################################################################################################
#                                                                                                 #
#     --- peakPantheR: detect and integrate pre-defined features in MS files using XCMS3 ---      #
#                                                                                                 #
###################################################################################################


#' Search, integrate and report targeted features in a raw spectra
#'
#' Report TIC and integrated targeted features in a raw spectra.
#'
#' @param singleSpectraDataPath (str) path to netCDF or mzML raw data file (centroided, \strong{only with the channel of interest}).
#' @param targetFeatTable a \code{\link{data.frame}} of compounds to target as rows. Columns: \code{cpdID} (int), \code{cpdName} (str), \code{rtMin} (float in seconds), \code{rt} (float in seconds, or \emph{NA}), \code{rtMax} (double in seconds), \code{mzMin} (float in seconds), \code{mz} (float in seconds, or \emph{NA}), \code{mzMax} (float in seconds).
#' @param fitGauss (bool) if TRUE fits peak with option \code{CentWaveParam(..., fitgauss=TRUE)}.
#' @param peakStatistic (bool) If TRUE calculates additional peak statistics: deviation, FWHM, Tailing factor, Assymetry factor
#' @param ... Passes arguments to \code{peakPantheR_findTargetFeature} to alter peak-picking parameters
#'
#' @return a list: \code{list()$TIC} \emph{(int)} TIC value, \code{list()$peakTable} \emph{data.frame} targeted features results (see Details).
#'
#' \subsection{Details:}{
#'   The returned \emph{peakTable} \code{data.frame} is structured as follow:
#'   \tabular{ll}{
#'     cpdID \tab database compound ID\cr
#'     cpdName \tab compound name\cr
#'     found \tab (bool) TRUE if compound was found in the raw data\cr
#'     mz \tab weighted (by intensity) mean of peak m/z across scans\cr
#'     mzmin \tab m/z peak minimum\cr
#'     mzmax \tab m/z peak maximum\cr
#'     rt \tab retention time of peak midpoint\cr
#'     rtmin \tab leading edge of peak retention time\cr
#'     rtmax \tab trailing edge of peak retention time\cr
#'     into \tab integrated peak intensity\cr
#'     intb \tab baseline corrected integrated peak intensity\cr
#'     maxo \tab maximum peak intensity\cr
#'     sn \tab Signal/Noise ratio, defined as \code{(maxo - baseline)/sd}, where \code{maxo} is the maximum peak intensity, \code{baseline} the estimated baseline value and \code{sd} the standard deviation of local chromatographic noise.\cr
#'     egauss \tab RMSE of Gaussian fit\cr
#'     mu \tab Gaussian parameter mu\cr
#'     sigma \tab Gaussian parameter sigma\cr
#'     h \tab Gaussian parameter h\cr
#'     f \tab Region number of m/z ROI where the peak was localised\cr
#'     dppm \tab m/z deviation of mass trace across scans in ppm\cr
#'     scale \tab Scale on which the peak was localised\cr
#'     scpos \tab Peak position found by wavelet analysis (scan number)\cr
#'     scmin \tab Left peak limit found by wavelet analysis (scan number)\cr
#'     scmax \tab Right peak limit found by wavelet analysis (scan number)\cr
#'     ppm_error \tab difference in ppm between the expected and measured m/z, not available if \code{peakStatistic=FALSE}\cr
#'     rt_dev_sec \tab difference in seconds between the expected and measured rt, not available if \code{peakStatistic=FALSE}\cr
#'     FWHM \tab full width at half maximum (in seconds), not available if \code{fitGauss=FALSE}, not available if \code{peakStatistic=FALSE}\cr
#'     FWHM_ndatapoints \tab number of scans on the peak, not available if \code{peakStatistic=FALSE}\cr
#'     tailingFactor \tab the tailing factor is a measure of peak tailing.It is defined as the distance from the front slope of the peak to the back slope divided by twice the distance from the center line of the peak to the front slope, with all measurements made at 5\% of the maximum peak height. The tailing factor of a peak will typically be similar to the asymmetry factor for the same peak, but the two values cannot be directly converted, not available if \code{peakStatistic=FALSE}\cr
#'     assymmetryFactor \tab the asymmetry factor is a measure of peak tailing. It is defined as the distance from the center line of the peak to the back slope divided by the distance from the center line of the peak to the front slope, with all measurements made at 10\% of the maximum peak height. The asymmetry factor of a peak will typically be similar to the tailing factor for the same peak, but the two values cannot be directly converted, not available if \code{peakStatistic=FALSE}\cr
#'   }
#' }
#'
#' @references Adapted for XCMS3 from Jan Stanstrup's tutorial https://cdn.rawgit.com/stanstrup/QC4Metabolomics/master/MetabolomiQCsR/inst/doc/standard_stats.html
#'
#' @examples
#' \donttest{
#' ## Load data
#' library(MSnbase)
#'
#' ## Raw data file
#' netcdffile <- './my_spectra.CDF'
#'
#' ## targetFeatTable from outside source
#' targetFeatTable            <- data.frame(matrix(vector(), 11, 8, dimnames=list(c(), c("cpdID", "cpdName", "rtMin", "rt", "rtMax", "mzMin", "mz", "mzMax"))), stringsAsFactors=F)
#' targetFeatTable[1,]        <- c(1, "LPC (9:0/0:0)", 29.4, NA, 38.4, 398.2108, 398.2308, 398.2508)
#' targetFeatTable[2,]        <- c(2, "PC (11:0/11:0)", 138.0, NA, 198.0, 594.3935, 594.4135, 594.4335)
#' targetFeatTable[,c(1,3:8)] <- sapply(targetFeatTable[,c(1,3:8)], as.numeric)
#'
#' res <- peakPantheR_cpdSearch(netcdfFile,targetFeatTable[1:2,], peakStatistic=TRUE)
#' # Polarity can not be extracted from netCDF files, please set manually the polarity with the 'polarity' method.
#' # Detecting chromatographic peaks in 2 regions of interest ... OK: 7 found.
#' # Found 2/2 features (7 total) in 27.8 secs
#' # Peak statistics done in: 10.37 secs
#' # QC search done in: 38.61 secs
#' res
#' # $TIC
#' # [1] 13406775774
#' #
#' # $peakTable
#' #    cpdID        cpdName found       mz    mzmin    mzmax      rt   rtmin   rtmax    into    intb
#' # 1      1  LPC (9:0/0:0)  TRUE 398.2319 398.2306 398.2330  33.296  31.468  35.352 1919498 1919222
#' # 2      2 PC (11:0/11:0)  TRUE 594.4140 594.4120 594.4149 179.046 176.762 181.103 2233011 2232784
#' #         maxo    sn     egauss       mu    sigma         h f dppm  scale scpos scmin scmax lmin
#' # 1   942711.5 15739 0.04867894 136.1303 3.458960  979537.2 1    3      4   136   132   140  128
#' # 2  1038315.5 30275 0.03296024 770.7220 3.832822 1034072.3 2    1     -1    -1    -1    -1  375
#' #    lmax sample is_filled ppm_error rt_dev_sec    FWHM FWHM_ndatapoints tailingFactor assymmetryFactor
#' # 1   145      1         0  2.744491         NA 1.86026                9     0.8868141        1.1248373
#' # 2   394      1         0  0.830051         NA      NA               NA     1.0053721        0.9744952
#' }
#'
#' @family peakPantheR
#' @family realTimeAnnotation
#' @family parallelAnnotation
#'
#' @import MSnbase
#'
#' @export
peakPantheR_cpdSearch <- function(singleSpectraDataPath, targetFeatTable, fitGauss=FALSE, peakStatistic=FALSE, ...) {
  stime <- Sys.time()

  # Check input
  if(!file.exists(singleSpectraDataPath)) {
    stop('Check input, file \"', singleSpectraDataPath ,'\" does not exist')
  }

  ## Read file
  raw_data  <- MSnbase::readMSData(singleSpectraDataPath, centroided=TRUE, mode='onDisk')

  ## Get TIC
  TICvalue  <- sum(MSnbase::tic(raw_data))#, initial=FALSE to calculate from raw and not header

  ## Generate Region of Interest List (ROIList)
  ROIList       <- peakPantheR_makeROIList(raw_data, targetFeatTable)

  ## Integrate features using ROI
  foundFeatTable <- peakPantheR_findTargetFeature(raw_data, ROIList, verbose=TRUE, fitGauss=fitGauss, ...)

  ## Add compound information
  finalOutput         <- foundFeatTable
  finalOutput$cpdID   <- targetFeatTable$cpdID
  finalOutput$cpdName <- targetFeatTable$cpdName

  ## Add deviation, FWHM, Tailing factor, Assymetry factor
  if(peakStatistic){
    statstime     <- Sys.time()
    finalOutput   <- peakPantheR_getTargetFeatureStatistic(raw_data, targetFeatTable, finalOutput)
    statetime     <- Sys.time()
    message('Peak statistics done in: ', round(as.double(difftime(statetime,statstime)),2),' ',units( difftime(statetime,statstime)))
  }
  etime <- Sys.time()
  message('QC search done in: ', round(as.double(difftime(etime,stime)),2),' ',units( difftime(etime,stime)))

  return(list(TIC=TICvalue, peakTable=finalOutput))
}




#' Generate a Region Of Interest (ROI) List
#'
#' Generate a ROIList as expected by \code{\link[xcms]{findChromPeaks}} from a \code{\link{data.frame}} with compounds to target as rows. \emph{length} and \emph{intensity} are set to \code{-1} as centWave does not use these values.
#'
#' @param rawSpec an \code{\link[MSnbase]{OnDiskMSnExp}} used to get the scans corresponding to each retention time.
#' @param targetFeatTable a \code{\link{data.frame}} of compounds to target as rows. Columns: \code{cpdID} (int), \code{cpdName} (str), \code{rtMin} (float in seconds), \code{rt} (float in seconds, or \emph{NA}), \code{rtMax} (double in seconds), \code{mzMin} (float in seconds), \code{mz} (float in seconds, or \emph{NA}), \code{mzMax} (float in seconds).
#'
#' @return a list of ROIs
#'
#' @examples
#' \donttest{
#' ## Load data
#' library(MSnbase)
#' netcdffile <- './my_spectra.CDF'
#' raw_data   <- MSnbase::readMSData(netcdffile, centroided=TRUE, mode='onDisk')
#'
#' ## targetFeatTable from outside source
#' targetFeatTable            <- data.frame(matrix(vector(), 11, 8, dimnames=list(c(), c("cpdID", "cpdName", "rtMin", "rt", "rtMax", "mzMin", "mz", "mzMax"))), stringsAsFactors=F)
#' targetFeatTable[1,]        <- c(1, "LPC (9:0/0:0)", 29.4, NA, 38.4, 398.2108, 398.2308, 398.2508)
#' targetFeatTable[2,]        <- c(2, "PC (11:0/11:0)", 138.0, NA, 198.0, 594.3935, 594.4135, 594.4335)
#' targetFeatTable[,c(1,3:8)] <- sapply(targetFeatTable[,c(1,3:8)], as.numeric)
#'
#' ROIList <- peakPantheR_makeROIList(raw_data, targetFeatTable)
#' ROIList[[1]]
#' # $mz
#' # [1] 398.2308
#' #
#' # $mzmin
#' # [1] 398.2108
#' #
#' # $mzmax
#' # [1] 398.2508
#' #
#' # $scmin
#' # [1] 119
#' #
#' # $scmax
#' # [1] 158
#' #
#' # $length
#' # [1] -1
#' #
#' # $intensity
#' # [1] -1
#' }
#'
#' @family peakPantheR
#' @family realTimeAnnotation
#' @family parallelAnnotation
#'
#' @import MSnbase
peakPantheR_makeROIList        <- function(rawSpec, targetFeatTable) {
  ROIList <- list()
  for (i in 1:dim(targetFeatTable)[1]) {
    # find the closest scan matching the retention time
    scmin <- which.min(abs(targetFeatTable$rtMin[i] - MSnbase::rtime(rawSpec)))[[1]]
    scmax <- which.min(abs(targetFeatTable$rtMax[i] - MSnbase::rtime(rawSpec)))[[1]]
    # mz, length and intensity are not used by centWave
    ROIList[[i]] <- list(mz=targetFeatTable$mz[i], mzmin=targetFeatTable$mzMin[i], mzmax=targetFeatTable$mzMax[i], scmin=scmin, scmax=scmax, length=-1, intensity=-1)
  }
  return(ROIList)
}




#' Integrate ROI and find target features
#'
#' Integrate features in the ROI using \code{CentWave} and keep in each ROI the feature with the highest integrated intensity.
#'
#' @param rawSpec an \code{\link[MSnbase]{OnDiskMSnExp}}
#' @param ROIList a list of ROIs as generated by \code{\link{peakPantheR_makeROIList}}
#' @param ppm \code{\link[xcms]{findChromPeaks-centWave}} parameter: \emph{maxmial tolerated m/z deviation in consecutive scans, in ppm (parts per million)}
#' @param snthresh \code{\link[xcms]{findChromPeaks-centWave}} parameter: \emph{signal to noise ratio cutoff}
#' @param noise \code{\link[xcms]{findChromPeaks-centWave}} parameter: \emph{optional argument which is useful for data that was centroided without any intensity threshold, centroids with intensity < \code{noise} are omitted from ROI detection}
#' @param prefilter \code{\link[xcms]{findChromPeaks-centWave}} parameter: \emph{\code{prefilter=c(k,I)}. Prefilter step for the first phase. Mass traces are only retained if they contain at least \code{k} peaks with intensity >= \code{I}.}
#' @param peakwidth \code{\link[xcms]{findChromPeaks-centWave}} parameter: \emph{Chromatographic peak width, given as range (min,max) in seconds}
#' @param verbose (bool) if TRUE message the time taken and number of features found (total and matched to targets)
#' @param fitGauss (bool) if TRUE fits peak with option \code{CentWaveParam(..., fitgauss=TRUE)}.
#'
#' @return A \code{data.frame} with targeted features as rows and peak measures as columns (see Details).
#'
#' \subsection{Details:}{
#'   The returned \code{data.frame} is structured as follow (from \code{\link[xcms]{findChromPeaks-centWave}}):
#'   \tabular{ll}{
#'     mz \tab weighted (by intensity) mean of peak m/z across scans\cr
#'     mzmin \tab m/z peak minimum\cr
#'     mzmax \tab m/z peak maximum\cr
#'     rt \tab retention time of peak midpoint\cr
#'     rtmin \tab leading edge of peak retention time\cr
#'     rtmax \tab trailing edge of peak retention time\cr
#'     into \tab integrated peak intensity\cr
#'     intb \tab baseline corrected integrated peak intensity\cr
#'     maxo \tab maximum peak intensity\cr
#'     sn \tab Signal/Noise ratio, defined as \code{(maxo - baseline)/sd}, where \code{maxo} is the maximum peak intensity, \code{baseline} the estimated baseline value and \code{sd} the standard deviation of local chromatographic noise.\cr
#'     egauss \tab RMSE of Gaussian fit\cr
#'     mu \tab Gaussian parameter mu\cr
#'     sigma \tab Gaussian parameter sigma\cr
#'     h \tab Gaussian parameter h\cr
#'     f \tab Region number of m/z ROI where the peak was localised\cr
#'     dppm \tab m/z deviation of mass trace across scans in ppm\cr
#'     scale \tab Scale on which the peak was localised\cr
#'     scpos \tab Peak position found by wavelet analysis (scan number)\cr
#'     scmin \tab Left peak limit found by wavelet analysis (scan number)\cr
#'     scmax \tab Right peak limit found by wavelet analysis (scan number)\cr
#'   }
#' }
#'
#' @examples
#' \donttest{
#' ## Load data
#' library(MSnbase)
#' netcdffile <- './my_spectra.CDF'
#' raw_data   <- MSnbase::readMSData(netcdffile, centroided=TRUE, mode='onDisk')
#'
#' ## targetFeatTable from outside source
#' targetFeatTable            <- data.frame(matrix(vector(), 11, 8, dimnames=list(c(), c("cpdID", "cpdName", "rtMin", "rt", "rtMax", "mzMin", "mz", "mzMax"))), stringsAsFactors=F)
#' targetFeatTable[1,]        <- c(1, "LPC (9:0/0:0)", 29.4, NA, 38.4, 398.2108, 398.2308, 398.2508)
#' targetFeatTable[2,]        <- c(2, "PC (11:0/11:0)", 138.0, NA, 198.0, 594.3935, 594.4135, 594.4335)
#' targetFeatTable[,c(1,3:8)] <- sapply(targetFeatTable[,c(1,3:8)], as.numeric)
#'
#' ROIList <- peakPantheR_makeROIList(raw_data, targetFeatTable)
#'
#' foundFeatTable <- peakPantheR_findTargetFeature(raw_data, ROIList)
#' foundFeatTable
#' #   found       mz    mzmin    mzmax      rt   rtmin   rtmax    into    intb      maxo    sn     egauss
#' # 1  TRUE 398.2319 398.2306 398.2330  33.296  31.468  35.352 1919498 1919222  942711.5 15739 0.04867894
#' # 2  TRUE 594.4140 594.4120 594.4149 179.046 176.762 181.103 2233011 2232784 1038315.5 30275 0.03296024
#' #          mu    sigma         h f dppm scale scpos scmin scmax lmin lmax sample is_filled
#' # 1 136.1303 3.458960  979537.2 1    3     4   136   132   140  128  145      1         0
#' # 2 770.7220 3.832822 1034072.3 2    1    -1    -1    -1    -1  375  394      1         0
#' }
#'
#' @family peakPantheR
peakPantheR_findTargetFeature <- function(rawSpec, ROIList, ppm=20, snthresh=3, noise=400, prefilter=c(7,400), peakwidth=c(2,20), verbose=FALSE, fitGauss=FALSE){
  stime <- Sys.time()

  ## Set centwave parameters and find peaks
  CWParam         <- xcms::CentWaveParam(roiList = ROIList, ppm = ppm, snthresh = snthresh, noise = noise, prefilter = prefilter, peakwidth = peakwidth, integrate = 1, verboseColumns = TRUE, fitgauss = fitGauss)
  resPeakSearch   <- xcms::findChromPeaks(rawSpec, param = CWParam)
  foundPeakTable  <- data.frame(xcms::chromPeaks(resPeakSearch))

  # Keep only the highest feature per ROI
  filteredFoundPeak <- data.frame(matrix(vector(), length(ROIList), (dim(foundPeakTable)[2]+1), dimnames=list(c(), c("found",colnames(foundPeakTable)))), stringsAsFactors=F)
  for (i in 1:dim(filteredFoundPeak)[1]) {
    if (i %in% foundPeakTable$f){
      # a peak has been found
      filteredFoundPeak[i,1]  <- TRUE
      filteredFoundPeak[i,-1] <- foundPeakTable[ foundPeakTable$f==i, ][ which.max( foundPeakTable[foundPeakTable$f==i,]$into), ]
    } else {
      # no peak found
      filteredFoundPeak[i,1] <- FALSE
    }
  }
  etime <- Sys.time()
  if (verbose) {
    message('Found ', sum(filteredFoundPeak$found), '/',length(ROIList), ' features (', dim(foundPeakTable)[1], ' total) in ', round(as.double(difftime(etime,stime)),2),' ',units( difftime(etime,stime)))
  }

  return(filteredFoundPeak)
}




#' Calculate chromatographic peak properties
#'
#' Calculate the ppm error, retention time deviation, FWHM, number of scans, tailing factor and assymmetry factor for each measured feature.
#'
#' @param rawSpec an \code{\link[MSnbase]{OnDiskMSnExp}}
#' @param targetFeatTable a \code{\link{data.frame}} of compounds to target as rows. Columns: \code{cpdID} (int), \code{cpdName} (str), \code{rtMin} (float in seconds), \code{rt} (float in seconds, or \emph{NA}), \code{rtMax} (double in seconds), \code{mzMin} (float in seconds), \code{mz} (float in seconds, or \emph{NA}), \code{mzMax} (float in seconds).
#' @param foundFeatTable a \code{data.frame} as generated by \code{\link{peakPantheR_findTargetFeature}}, with features as rows and peak properties as columns. The following columns are mandatory: \code{mz}, \code{rt}, \code{scmin}, \code{scpos}, \code{scmax}, \code{sigma}.
#'
#' @return A \code{data.frame} with measured compounds as rows and measurements and properties as columns (see Details).
#'
#' \subsection{Details:}{
#'   The returned \code{data.frame} is structured as follow:
#'   \tabular{ll}{
#'     cpdID \tab database compound ID\cr
#'     cpdName \tab compound name\cr
#'     found \tab (bool) TRUE if compound was found in the raw data\cr
#'     mz \tab weighted (by intensity) mean of peak m/z across scans\cr
#'     mzmin \tab m/z peak minimum\cr
#'     mzmax \tab m/z peak maximum\cr
#'     rt \tab retention time of peak midpoint\cr
#'     rtmin \tab leading edge of peak retention time\cr
#'     rtmax \tab trailing edge of peak retention time\cr
#'     into \tab integrated peak intensity\cr
#'     intb \tab baseline corrected integrated peak intensity\cr
#'     maxo \tab maximum peak intensity\cr
#'     sn \tab Signal/Noise ratio, defined as \code{(maxo - baseline)/sd}, where \code{maxo} is the maximum peak intensity, \code{baseline} the estimated baseline value and \code{sd} the standard deviation of local chromatographic noise.\cr
#'     egauss \tab RMSE of Gaussian fit\cr
#'     mu \tab Gaussian parameter mu\cr
#'     sigma \tab Gaussian parameter sigma\cr
#'     h \tab Gaussian parameter h\cr
#'     f \tab Region number of m/z ROI where the peak was localised\cr
#'     dppm \tab m/z deviation of mass trace across scans in ppm\cr
#'     scale \tab Scale on which the peak was localised\cr
#'     scpos \tab Peak position found by wavelet analysis (scan number)\cr
#'     scmin \tab Left peak limit found by wavelet analysis (scan number)\cr
#'     scmax \tab Right peak limit found by wavelet analysis (scan number)\cr
#'     ppm_error \tab difference in ppm between the expected and measured m/z\cr
#'     rt_dev_sec \tab difference in seconds between the expected and measured rt\cr
#'     FWHM \tab full width at half maximum (in seconds), not available if \code{fitGauss=FALSE}\cr
#'     FWHM_ndatapoints \tab number of scans on the peak\cr
#'     tailingFactor \tab the tailing factor is a measure of peak tailing.It is defined as the distance from the front slope of the peak to the back slope divided by twice the distance from the center line of the peak to the front slope, with all measurements made at 5\% of the maximum peak height. The tailing factor of a peak will typically be similar to the asymmetry factor for the same peak, but the two values cannot be directly converted\cr
#'     assymmetryFactor \tab the asymmetry factor is a measure of peak tailing. It is defined as the distance from the center line of the peak to the back slope divided by the distance from the center line of the peak to the front slope, with all measurements made at 10\% of the maximum peak height. The asymmetry factor of a peak will typically be similar to the tailing factor for the same peak, but the two values cannot be directly converted\cr
#'   }
#' }
#'
#' @references Adapted for XCMS3 from Jan Stanstrup https://cdn.rawgit.com/stanstrup/QC4Metabolomics/master/MetabolomiQCsR/inst/doc/standard_stats.html#calculating-statistics
#'
#' @examples
#' \donttest{
#' ## Load data
#' library(MSnbase)
#' netcdffile <- './my_spectra.CDF'
#' raw_data   <- MSnbase::readMSData(netcdffile, centroided=TRUE, mode='onDisk')
#'
#' ## targetFeatTable from outside source
#' targetFeatTable            <- data.frame(matrix(vector(), 11, 8, dimnames=list(c(), c("cpdID", "cpdName", "rtMin", "rt", "rtMax", "mzMin", "mz", "mzMax"))), stringsAsFactors=F)
#' targetFeatTable[1,]        <- c(1, "LPC (9:0/0:0)", 29.4, NA, 38.4, 398.2108, 398.2308, 398.2508)
#' targetFeatTable[2,]        <- c(2, "PC (11:0/11:0)", 138.0, NA, 198.0, 594.3935, 594.4135, 594.4335)
#' targetFeatTable[,c(1,3:8)] <- sapply(targetFeatTable[,c(1,3:8)], as.numeric)
#'
#' ROIList       <- peakPantheR_makeROIList(raw_data, targetFeatTable)
#'
#' foundFeatTable <- peakPantheR_findTargetFeature(raw_data, ROIList)
#'
#' finalOutput   <- peakPantheR_getTargetFeatureStatistic(raw_data, targetFeatTable, foundFeatTable)
#' finalOutput
#' #    cpdID        cpdName found       mz    mzmin    mzmax      rt   rtmin   rtmax    into    intb
#' # 1      1  LPC (9:0/0:0)  TRUE 398.2319 398.2306 398.2330  33.296  31.468  35.352 1919498 1919222
#' # 2      2 PC (11:0/11:0)  TRUE 594.4140 594.4120 594.4149 179.046 176.762 181.103 2233011 2232784
#' #         maxo    sn     egauss       mu    sigma         h f dppm  scale scpos scmin scmax lmin
#' # 1   942711.5 15739 0.04867894 136.1303 3.458960  979537.2 1    3      4   136   132   140  128
#' # 2  1038315.5 30275 0.03296024 770.7220 3.832822 1034072.3 2    1     -1    -1    -1    -1  375
#' #    lmax sample is_filled ppm_error rt_dev_sec    FWHM FWHM_ndatapoints tailingFactor assymmetryFactor
#' # 1   145      1         0  2.744491         NA 1.86026                9     0.8868141        1.1248373
#' # 2   394      1         0  0.830051         NA      NA               NA     1.0053721        0.9744952
#' }
#'
#' @family peakPantheR
peakPantheR_getTargetFeatureStatistic <- function(rawSpec, targetFeatTable, foundFeatTable) {

  ## Define the peak_shape_stat() -----------------------
  #
  # Calculate tailing factor and assymmetry factor
  #
  # Tailing Factor and Assymmetry Factor following the equations from http://www.chromforum.org/viewtopic.php?t=20079
  #
  # @param featEIC A single EIC as generated by \code{\link[xcms]{chromatogram}}
  # @param apexRT (float) retention time in seconds of the measured peak apex
  # @param statistic (str) either \code{tailingFactor} or \code{assymmetryFactor}
  # @param verbose (bool) if TRUE message when NA scans are removed
  #
  # @return Tailing factor or Assymmetry factor value
  #
  # @references Adapted for XCMS3 from QC4Metabolomics by Jan Stanstrup https://github.com/stanstrup/QC4Metabolomics/blob/master/MetabolomiQCsR/R/standard_stats.R
  # @references Equations from http://www.chromforum.org/viewtopic.php?t=20079
  #
  peak_shape_stat <- function(featEIC, apexRT, statistic="tailingFactor", verbose=FALSE){

    # A B and C are retention time in seconds. C is RT of the apex, A is left side as x%, B is right side at x%. x% (cutoff) depends of the statistic employed.

    #check inputs
    if(is.na(apexRT)) return(NA)

    # Remove scans with intensity NA from the feature
    if (sum(is.na(xcms::intensity(featEIC))) != 0) {
      if(verbose){
        message(sum(is.na(xcms::intensity(featEIC))), '/', length(xcms::intensity(featEIC)), ' scans removed due to NA')
      }
      filterNA    <- !is.na(xcms::intensity(featEIC))
      featEIC_RT  <- xcms::rtime(featEIC)[filterNA]
      featEIC_Int <- xcms::intensity(featEIC)[filterNA]
    } else {
      featEIC_RT  <- xcms::rtime(featEIC)
      featEIC_Int <- xcms::intensity(featEIC)
    }

    # get the scan number of the RT apex
    apexRT_scan_number <- which.min(abs(featEIC_RT - apexRT))
    # the RT matching this apex (also known as C)
    C   <- featEIC_RT[apexRT_scan_number]

    # ensure we don't overshoot the index
    # -2 / +2
    if( (apexRT_scan_number-2)>=1 ){ startRange2pt <- apexRT_scan_number-2 }
    else { startRange2pt <- 1}
    if( (apexRT_scan_number+2)<=length(featEIC_RT) ){ endRange2pt <- apexRT_scan_number+2 }
    else { endRange2pt <- length(featEIC_RT) }
    # -1 / +1
    if( (apexRT_scan_number-1)>=1 ){ startRange1pt <- apexRT_scan_number-1 }
    else { startRange1pt <- 1}
    if( (apexRT_scan_number+1)<=length(featEIC_RT) ){ endRange1pt <- apexRT_scan_number+1 }
    else { endRange1pt <- length(featEIC_RT) }

    # maximum intensity across the 5 central scans to avoid problems if the center is not the highest
    max_int <- max(featEIC_Int[startRange2pt:endRange2pt], na.rm = TRUE)

    # check values are non-0 for 3 central scans, otherwise exit
    if( all( featEIC_Int[(startRange1pt):(endRange1pt)] == 0) ) return(NA)


    # Median smoothing. Avoids single zero values breaking things. Already smooth peaks are unaffected.
    if(  !all( c(featEIC_Int[startRange1pt], featEIC_Int[endRange1pt]) == 0 )  ){ # If the values on each side of the mid of the peak are both 0 don't do smoothing (a 1 scan spike would cause this).
      featEIC_Int  <- stats::smooth(featEIC_Int, kind="3")
    }


    # If middle scan is zero after smoothing, exit
    if( featEIC_Int[apexRT_scan_number] == 0 ) return(NA)


    # Left side of the peak
    # Get each scan RT, reverse order, normalise by max_intensity (so just need to look for x% (cutoff) no need to divide later)
    A_side_rt       <- rev(featEIC_RT[1:apexRT_scan_number]) # can use featEIC as RT didn't change
    # Get scan, reverse order, normalise by max_intensity (so just need to look for x% (cutoff) no need to divide later)
    A_side_normInt  <- rev(featEIC_Int[1:apexRT_scan_number])/max_int

    # Right side of the peak
    # Get each scan RT
    B_side_rt       <- featEIC_RT[apexRT_scan_number:length(MSnbase::rtime(featEIC))] # can use featEIC as RT didn't change
    # Get scan, normalise by max_intensity
    B_side_normInt  <- featEIC_Int[apexRT_scan_number:length(featEIC_Int)]/max_int


    # Change the cut-off depending on the statistic
    cutoff <- switch(statistic, tailingFactor=0.05, assymmetryFactor=0.1)

    ## Get A (left side)
    # Keep points all points > cutoff and 1 point < cutoff, then interpolate cutoff retention time
    A_cutoff_pt     <- match(-1,sign(A_side_normInt - cutoff)) # positions of scans up to when it's too far (if negative, we are past the cutoff)
    if (!is.na(A_cutoff_pt)) {
      A_scans_toKeep  <- seq(1, A_cutoff_pt)
      A_side_rt       <- A_side_rt[A_scans_toKeep]
      A_side_normInt  <- A_side_normInt[A_scans_toKeep]
      # Check there was a point over cutoff (only 1 point, can't work)
      if( length(A_scans_toKeep)==1 ) return(NA)
    } else {
      return(NA)
    }

    # Approximate the RT at the cutoff intensity
    A <- stats::approx(x=A_side_normInt, y=A_side_rt, xout=cutoff)$y


    # Get B (right side)
    # Keep points all points > cutoff and 1 point < cutoff, then interpolate cutoff retention time
    B_cutoff_pt     <- match(-1,sign(B_side_normInt - cutoff)) # positions of scans up to when it's too far (if negative, we are past the cutoff)
    if (!is.na(B_cutoff_pt)) {
      B_scans_toKeep  <- seq(1, B_cutoff_pt)
      B_side_rt       <- B_side_rt[B_scans_toKeep]
      B_side_normInt  <- B_side_normInt[B_scans_toKeep]
      # Check there was a point over cutoff (only 1 point, can't work)
      if( length(B_scans_toKeep)==1 ) return(NA)
    } else {
      return(NA)
    }

    # Approximate the RT at the cutoff intensity
    B <- stats::approx(x=B_side_normInt, y=B_side_rt, xout=cutoff)$y

    # remove the name from the named float
    if(statistic=="tailingFactor") {
      result <- (B-A)/(2*(C-A))
      return( result[[1]] )
    }
    if(statistic=="assymmetryFactor") {
      result <- (B-C)/(C-A)
      return( result[[1]] )
    }
  }

  ## ----------------------------------------------------

  if (dim(targetFeatTable)[1] != dim(foundFeatTable)[1]) {
    stop("Number of features in targetFeatTable (", dim(targetFeatTable)[1],") and foundFeatTable (", dim(foundFeatTable)[1], ") do not match!")
  }

  ## Extract found features EICs from raw data
  EICs        <- xcms::chromatogram(rawSpec, rt = data.frame(rt_lower=targetFeatTable$rtMin, rt_upper=targetFeatTable$rtMax), mz = data.frame(mz_lower=targetFeatTable$mzMin, mz_upper=targetFeatTable$mzMax))

  ## Calculate the statistics
  peakStat    <- data.frame(matrix(vector(), dim(targetFeatTable)[1], 6, dimnames=list(c(), c("ppm_error", "rt_dev_sec", "FWHM", "FWHM_ndatapoints", "tailingFactor", "assymmetryFactor"))), stringsAsFactors=F)

  for (i in 1:dim(targetFeatTable)[1]) {
    # If the feature wasn't found we cannot work with it
    if (foundFeatTable$found[i]) {
      # ppm_error
      if (!is.na(targetFeatTable$mz[i])) {
        peakStat$ppm_error[i] <- (abs(foundFeatTable$mz[i] - targetFeatTable$mz[i])/targetFeatTable$mz[i])*1E6
      }
      # rt_dev_sec
      if (!is.na(targetFeatTable$rt[i])) {
        peakStat$rt_dev_sec[i] <- abs(foundFeatTable$rt[i] - targetFeatTable$rt[i])
      }

      # FWHM
      # need a function to approximate retention time between the existing scans
      if ((foundFeatTable$scpos[i]!=-1) & (foundFeatTable$scmin[i]!=-1) & (foundFeatTable$scmax[i]!=-1)) {
        approx_rt_from_scan <- stats::approxfun( seq_along( xcms::rtime(rawSpec)), xcms::rtime(rawSpec) ) # approximation of RT at any scan (even not integer)
        FWHM_scan           <- 2*sqrt(2*log(2))*foundFeatTable$sigma[i]
        FWHM_start          <- approx_rt_from_scan(foundFeatTable$scpos[i] - FWHM_scan/2) # min rt at half height (calculate the min scan at half height, convert to a RT with approx function)
        FWHM_end            <- approx_rt_from_scan(foundFeatTable$scpos[i] + FWHM_scan/2)
        peakStat$FWHM[i]             <- FWHM_end - FWHM_start
        peakStat$FWHM_ndatapoints[i] <- (foundFeatTable$scmax[i] - foundFeatTable$scmin[i]) + 1 # number of datapoints for peak measurement
      }
      # Tailing Factor
      peakStat$tailingFactor[i]      <- peak_shape_stat(EICs[[i]], foundFeatTable$rt[i], statistic = "tailingFactor")
      # Assymmetry Factor
      peakStat$assymmetryFactor[i]   <- peak_shape_stat(EICs[[i]], foundFeatTable$rt[i], statistic = "assymmetryFactor")
    }
  }

  ## group the results and return
  finalTable  <- cbind.data.frame(foundFeatTable, peakStat)
  return( finalTable )
}