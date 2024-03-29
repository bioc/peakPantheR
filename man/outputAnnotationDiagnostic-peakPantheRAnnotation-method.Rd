% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods_peakPantheRAnnotation.R
\docType{methods}
\name{outputAnnotationDiagnostic,peakPantheRAnnotation-method}
\alias{outputAnnotationDiagnostic,peakPantheRAnnotation-method}
\alias{outputAnnotationDiagnostic}
\title{Save to disk the annotation parameters as CSV and a diagnostic plot
per fitted compound}
\usage{
\S4method{outputAnnotationDiagnostic}{peakPantheRAnnotation}(
    object,
    saveFolder,
    savePlots = TRUE,
    sampleColour = NULL,
    verbose = TRUE,
    ncores = 0,
    svgPlot = FALSE,
    ...
)
}
\arguments{
\item{object}{(peakPantheRAnnotation) Annotated peakPantheRAnnotation object}

\item{saveFolder}{(str) Path of folder where annotationParameters_summary.csv
and plots will be saved}

\item{savePlots}{(bool) If TRUE save a diagnostic plot for each compound}

\item{sampleColour}{(str) NULL or vector colour for each sample}

\item{verbose}{(bool) If TRUE message progress}

\item{ncores}{(int) Number of cores to use to save plots in parallel}

\item{svgPlot}{(bool) If TRUE save plots as 'svg', otherwise as 'png'}

\item{...}{Additional parameters for plotting i.e. \code{sampling} for the
number of points to employ when plotting fittedCurve}
}
\value{
None
}
\description{
Save to disk the annotation parameters as CSV (as generated by
\code{outputAnnotationParamsCSV()}) and a diagnostic plot per fitted compound
(as generated by \code{annotationDiagnosticMultiplot()}) if \code{savePlots}
is TRUE
}
\examples{
if(requireNamespace('faahKO')){
## Initialise a peakPantheRAnnotation object with 3 samples and 2 targeted
## compounds

# Paths to spectra files
library(faahKO)
spectraPaths <- c(system.file('cdf/KO/ko15.CDF', package = 'faahKO'),
                    system.file('cdf/KO/ko16.CDF', package = 'faahKO'),
                    system.file('cdf/KO/ko18.CDF', package = 'faahKO'))

# targetFeatTable
targetFeatTable <- data.frame(matrix(vector(), 2, 8, dimnames=list(c(),
                    c('cpdID','cpdName','rtMin','rt','rtMax','mzMin','mz',
                    'mzMax'))), stringsAsFactors=FALSE)
targetFeatTable[1,] <- c('ID-1', 'Cpd 1', 3310., 3344.888, 3390., 522.194778,
                        522.2, 522.205222)
targetFeatTable[2,] <- c('ID-2', 'Cpd 2', 3280., 3385.577, 3440., 496.195038,
                        496.2, 496.204962)
targetFeatTable[,c(3:8)] <- vapply(targetFeatTable[,c(3:8)], as.numeric,
                                    FUN.VALUE=numeric(2))

emptyAnnotation <- peakPantheRAnnotation(spectraPaths=spectraPaths,
                                        targetFeatTable=targetFeatTable)

# Calculate annotation
annotation <- peakPantheR_parallelAnnotation(emptyAnnotation, ncores=0,
                                getAcquTime=FALSE, verbose=FALSE)$annotation

# temporary location
savePath1       <- tempdir()
outputAnnotationDiagnostic(annotation, saveFolder=savePath1, savePlots=FALSE,
                            verbose=TRUE)
}
}
