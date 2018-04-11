#' Plot samples raw data and detected feature for a single ROI
#'
#' plot a ROI  across multiple samples (x axis is RT, y axis is intensity) with the matching detected peak rt and peakwidth under it. RT and peakwidth are plotted in the order spectra are passed, with the first spectra on top.
#'
#' @param EICs list of xcms::chromatograms (containing a single spectra each). If it is a xcms::Chromatogram (no S) or not a list, bring it to the right format.
#' @param cpdID (str) Compound ID
#' @param cpdName (str) Compound Name
#' @param rt (float) vector of detected peak apex retention time (in sec)
#' @param rtmin (float) vector of detected peak minimum retention time (in sec)
#' @param rtmax (float) vector ofdetected peak maximum retention time (in sec)
#' @param mzmin (float) ROI minimum m/z (matching EIC)
#' @param mzmax (float) ROI maximum m/z (matching EIC)
#' @param ratio (float) value between 0 and 1 defining the vertical percentage taken by the EICs subplot
#' @param sampleColour (str) NULL or vector colour for each sample (same length as \code{EICs}, \code{rt}, \code{rtmin}, \code{rtmax})
#' @param verbose (bool) if TRUE message when NA scans are removed
#' 
#' @return Grob (ggplot object)
plotEICDetectedPeakwidth  <- function(EICs, cpdID, cpdName, rt, rtmin, rtmax, mzmin, mzmax, ratio=0.85, sampleColour=NULL, verbose=TRUE) {
  
  ## Check input
  # in case EICs is not a list
  if (class(EICs) != "list") {
    stop('Error: EICs must be a list of single xcms::Chromatograms')
  }
  
  nbSpl   <- length(EICs)
  if ((nbSpl!=length(rt)) | (nbSpl!=length(rtmin)) | (nbSpl!=length(rtmax))) {
    stop("'EIC', 'rt', 'rtmin' and 'rtmax' must be the same length")
  }
  
  # set default colour (add a sample color ID that will be match in the plot)
  colourSpl  <- rep("black", nbSpl)
  if (!is.null(sampleColour)) {
    if (nbSpl==length(sampleColour)) {
      colourSpl <- sampleColour
    } else {
      if (verbose) {message('Warning: sampleColour length must match the number of samples; default colour used')}
    }
  } 
  sampleIDColour    <- paste('spl', seq(1:nbSpl), sep="")
  names(colourSpl)  <- sampleIDColour
  
  # ratio must be between 0 and 1
  if ((ratio < 0) | (ratio > 1)) {
    if (verbose) {message('Error: ratio must be between 0 and 1, replaced by default value')}
    ratio <- 0.85
  }
  
  
  ## Init
  title   <- paste('CpdID: ', cpdID, ' - ', cpdName, ' ', round(mzmin, 4), '-', round(mzmax, 4))
  
  ## Plot raw spectra
  # init plot
  p_spec      <- ggplot2::ggplot(NULL, ggplot2::aes(x), environment = environment()) + ggplot2::ggtitle(title) + ggplot2::theme_bw() + ggplot2::ylab('Intensity') + ggplot2::theme(axis.title.x=ggplot2::element_blank(), axis.text.x=ggplot2::element_blank(), plot.title=ggplot2::element_text(size=ggplot2::rel(1)))
  # add each spectra to the plot
  for (spectraID in 1:nbSpl){
    # in case EICs is a single Chromatogram instead of a Chromatograms
    if (class(EICs[[spectraID]]) != "Chromatograms") {
      stop('Error: EICs must be a list of single xcms::Chromatograms')
    }
    # prepare data
    if (length(EICs[[spectraID]]) > 1) {
      message('Warning: more than 1 spectra per Chromatograms provided! Only the first one will be considered')
    }
    Int       <- xcms::intensity(EICs[[spectraID]][1])
    filterNA  <- !is.na(Int)
    Int       <- Int[filterNA]
    RT        <- xcms::rtime(EICs[[spectraID]][1])[filterNA]
    # plot
    p_spec    <- p_spec + ggplot2::geom_line(data=data.frame(x=RT, y=Int), ggplot2::aes_string(x="x", y="y"), colour=colourSpl[spectraID])
  }
  
  
  ## Plot peakwidth
  y_placement   <- seq(nbSpl-1, 0) #first spectra on top
  # init plot
  p_peakwidth   <- ggplot2::ggplot(NULL, ggplot2::aes(x), environment = environment()) + ggplot2::theme_bw() + ggplot2::xlab('Retention Time (sec)') + ggplot2::theme(axis.title.y=ggplot2::element_blank(), axis.text.y=ggplot2::element_blank(), axis.ticks.y=ggplot2::element_blank()) + ggplot2::scale_y_continuous(breaks=NULL)
  # set colourscale for p_peakwidth
  tmp_col         <- colourSpl
  p_peakwidth     <- p_peakwidth + ggplot2::scale_colour_manual(values=tmp_col, guide=FALSE)
  # rt point (add the color ID to each point)
  tmp_pt        <- data.frame(x=rt, y=y_placement, colr=sampleIDColour, stringsAsFactors=F)
  tmp_pt        <- tmp_pt[!is.na(tmp_pt$x),]
  p_peakwidth   <- p_peakwidth + ggplot2::geom_point(data=tmp_pt, ggplot2::aes(x=x, y=y, colour=colr), size=3)
  # rt peakwidth (add color ID to each point)
  tmp_pwidth    <- data.frame(x=c(rtmin,rtmax), y=c(y_placement,y_placement), colr=c(sampleIDColour,sampleIDColour), stringsAsFactors=F)
  tmp_pwidth    <- tmp_pwidth[!is.na(tmp_pwidth$x),]
  p_peakwidth   <- p_peakwidth + ggplot2::geom_line(data=tmp_pwidth, ggplot2::aes(x=x, y=y, group=y, colour=colr), size=1)
  
  
  ## Set common x lim
  minX          <- min(ggplot2::layer_scales(p_spec)$x$range$range[1], ggplot2::layer_scales(p_peakwidth)$x$range$range[1])
  maxX          <- max(ggplot2::layer_scales(p_spec)$x$range$range[2], ggplot2::layer_scales(p_peakwidth)$x$range$range[2])
  p_spec        <- p_spec + ggplot2::xlim(minX, maxX)
  p_peakwidth   <- p_peakwidth + ggplot2::xlim(minX, maxX)
  # convert to gtables
  p_spec        <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(p_spec))
  p_peakwidth   <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(p_peakwidth))
  #  find the widths of each of the plots, calculate the maximum and then apply it to each of them individually. This effectively applies a uniform layout to each of the plots.
  maxWidth                <- grid::unit.pmax(p_spec$widths[2:3], p_peakwidth$widths[2:3])
  p_spec$widths[2:3]      <- maxWidth
  p_peakwidth$widths[2:3] <- maxWidth
  
  # Group plots with y axis ratio
  topSize     <- ratio * 10
  bottomSize  <- (1-ratio) * 10
  p           <- gridExtra::grid.arrange(p_spec, p_peakwidth, heights=c(topSize, bottomSize))
  
  return(p)
}