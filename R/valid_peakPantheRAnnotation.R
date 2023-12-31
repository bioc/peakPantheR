## valid method for \link{peakPantheRAnnotation-class}
## Number of compounds based on @cpdID length, number of samples based on
## @filepath length.
## Slot type is not checked as \code{setClass} enforces it.
## peakTables, peakFit and dataPoints type are checked on first list element.
valid_peakPantheRAnnotation <- function(object) {
    # init
    msg <- NULL
    valid <- TRUE
    nbCpd <- length(object@cpdID)
    nbSample <- length(object@filepath)

    # number of cpdName
    vcheck <- valid_ppR_cpdName(object, valid, msg, nbCpd)
    valid <- vcheck$valid; msg <- vcheck$msg
    # ROI nb rows, nb columns, column names, column types
    vcheck <- valid_ppR_ROI(object, valid, msg, nbCpd)
    valid <- vcheck$valid; msg <- vcheck$msg
    # FIR nb rows, nb columns, column names, column types
    vcheck <- valid_ppR_FIR(object, valid, msg, nbCpd)
    valid <- vcheck$valid; msg <- vcheck$msg
    # uROI nb rows, nb columns, column names, column types
    vcheck <- valid_ppR_uROI(object, valid, msg, nbCpd)
    valid <- vcheck$valid; msg <- vcheck$msg
    # number of compounds (rows) in cpdMetadata
    vcheck <- valid_ppR_cpdMetadata(object, valid, msg, nbCpd)
    valid <- vcheck$valid; msg <- vcheck$msg
    # number of spectra (rows) in spectraMetadata
    vcheck <- valid_ppR_spectraMetadata(object, valid, msg, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg
    # number of acquisitionTime
    vcheck <- valid_ppR_acquisitionTime(object, valid, msg, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg
    # cannot useUROI if uROIExist=FALSE
    vcheck <- valid_ppR_useUROIuROIExist(object, valid, msg)
    valid <- vcheck$valid; msg <- vcheck$msg
    # number of TIC
    vcheck <- valid_ppR_TIC(object, valid, msg, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg
    # peakTables (nb, type, nb of rows, nb columns, column names)
    vcheck <- valid_ppR_peakTables(object, valid, msg, nbCpd, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg
    # dataPoints (nb, type, nb of rows, nb columns, column names)
    vcheck <- valid_ppR_dataPoints(object, valid, msg, nbCpd, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg
    # peakFit (nb, type, nb of rows, nb columns, column names)
    vcheck <- valid_ppR_peakFit(object, valid, msg, nbCpd, nbSample)
    valid <- vcheck$valid; msg <- vcheck$msg

    # output
    if (valid) { return(TRUE) } else { return(msg) }
}


# -----------------------------------------------------------------------------
# valid_peakPantheRAnnotation helper functions

## number of cpdName
valid_ppR_cpdName <- function(object, valid, msg, nbCpd) {
    if (length(object@cpdName) != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("cpdName has ", length(object@cpdName),
            " elements (compound). Should be ",  nbCpd))
    }
    return(list(valid=valid, msg=msg))
}

## ROI (nb rows, nb columns, column names, column types)
valid_ppR_ROI <- function(object, valid, msg, nbCpd) {
    # ROI number of rows
    if (dim(object@ROI)[1] != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("ROI has ", dim(object@ROI)[1],
            " rows (compound). Should be ", nbCpd)) }
    # ROI number of columns
    if (dim(object@ROI)[2] != 6) {
        valid <- FALSE
        msg <- c(msg, paste0("ROI has ", dim(object@ROI)[2], " columns. Should",
        " be 6 (\"rtMin\", \"rt\", \"rtMax\", \"mzMin\", \"mz\", \"mzMax\")"))
    } else {
        # ROI column names
        if (!all(colnames(object@ROI) %in% c("rtMin", "rt", "rtMax", "mzMin",
            "mz", "mzMax"))) {
            valid <- FALSE
            msg <- c(msg, paste0('ROI columns should be \"rtMin\", \"rt\", ',
                '\"rtMax\", \"mzMin\", \"mz\", \"mzMax\", not ',
                paste(colnames(object@ROI), collapse = " ")))
        } else {
            vcheck <- valid_ppR_ROI_content(object, valid, msg, nbCpd)
            valid <- vcheck$valid; msg <- vcheck$msg
        }
    }
    return(list(valid=valid, msg=msg))
}
# check NA and column types, split due to function length
valid_ppR_ROI_content <- function(object, valid, msg, nbCpd){
    # Missing rtMin, rtMax, mzMin or mzMax
    if (any(is.na(object@ROI[,c("rtMin","rtMax","mzMin","mzMax")]))) {
        valid <- FALSE
        msg <- c(msg, paste0("ROI$rtMin, ROI$rtMax, ROI$mzMin and ",
                            "ROI$mzMax cannot be NA")) }
    # ROI column type
    if (nbCpd >= 1) {
        if (!is.numeric(object@ROI$rtMin[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$rtMin should be numeric, not ",
                                typeof(object@ROI$rtMin[1]))) }
        if (!is.numeric(object@ROI$rt[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$rt should be numeric, not ",
                                typeof(object@ROI$rt[1]))) }
        if (!is.numeric(object@ROI$rtMax[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$rtMax should be numeric, not ",
                                typeof(object@ROI$rtMax[1]))) }
        if (!is.numeric(object@ROI$mzMin[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$mzMin should be numeric, not ",
                                typeof(object@ROI$mzMin[1]))) }
        if (!is.numeric(object@ROI$mz[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$mz should be numeric, not ",
                                typeof(object@ROI$mz[1]))) }
        if (!is.numeric(object@ROI$mzMax[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("ROI$mzMax should be numeric, not ",
                                typeof(object@ROI$mzMax[1]))) }}
    return(list(valid=valid, msg=msg))
}

## FIR (nb rows, nb columns, column names, column types)
valid_ppR_FIR <- function(object, valid, msg, nbCpd) {
    # FIR number of rows
    if (dim(object@FIR)[1] != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("FIR has ", dim(object@FIR)[1],
                            " rows (compound). Should be ", nbCpd)) }
    # FIR number of columns
    if (dim(object@FIR)[2] != 4) {
        valid <- FALSE
        msg <- c(msg, paste0("FIR has ", dim(object@FIR)[2],
        " columns. Should be 4 (\"rtMin\", \"rtMax\", \"mzMin\", \"mzMax\")"))
    } else {
        # FIR column names
        if (!all(colnames(object@FIR) %in%
            c("rtMin", "rtMax", "mzMin", "mzMax"))) {
            valid <- FALSE
            msg <- c(msg, paste0('FIR columns should be \"rtMin\", \"rtMax\", ',
                                '\"mzMin\", \"mzMax\", not ',
                                paste(colnames(object@FIR), collapse = " ")))
        } else {
            # Missing rtMin, rtMax, mzMin or mzMax
            if (object@useFIR) {
                # FIR is set to NA when not in use
                if (any(is.na(object@FIR$rtMin))|any(is.na(object@FIR$rtMax))|
                    any(is.na(object@FIR$mzMin))|any(is.na(object@FIR$mzMax))) {
                    valid <- FALSE
                    msg <- c(msg, paste0("FIR$rtMin, FIR$rtMax, FIR$mzMin and ",
                                        "FIR$mzMax cannot be NA")) }
            }
            # FIR column type
            if (nbCpd >= 1) {
                if (!is.numeric(object@FIR$rtMin[1])) {
                    valid <- FALSE
                    msg <- c(msg, paste0("FIR$rtMin should be numeric, not ",
                                        typeof(object@FIR$rtMin[1]))) }
                if (!is.numeric(object@FIR$rtMax[1])) {
                    valid <- FALSE
                    msg <- c(msg, paste0("FIR$rtMax should be numeric, not ",
                                        typeof(object@FIR$rtMax[1]))) }
                if (!is.numeric(object@FIR$mzMin[1])) {
                    valid <- FALSE
                    msg <- c(msg, paste0("FIR$mzMin should be numeric, not ",
                                        typeof(object@FIR$mzMin[1]))) }
                if (!is.numeric(object@FIR$mzMax[1])) {
                    valid <- FALSE
                    msg <- c(msg, paste0("FIR$mzMax should be numeric, not ",
                                        typeof(object@FIR$mzMax[1]))) }}}}
    return(list(valid=valid, msg=msg))
}

## uROI (nb rows, nb columns, column names, column types)
valid_ppR_uROI <- function(object, valid, msg, nbCpd) {
    # uROI number of rows
    if (dim(object@uROI)[1] != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("uROI has ", dim(object@uROI)[1],
                            " rows (compound). Should be ", nbCpd)) }
    # uROI number of columns
    if (dim(object@uROI)[2] != 6) {
        valid <- FALSE
        msg <- c(msg, paste0("uROI has ",dim(object@uROI)[2],' columns. Should',
        ' be 6 (\"rtMin\", \"rt\", \"rtMax\", \"mzMin\", \"mz\", \"mzMax\")'))
    } else {
        # uROI column names
        if (!all(colnames(object@uROI) %in% c("rtMin", "rt", "rtMax", "mzMin",
                                                "mz", "mzMax"))) {
            valid <- FALSE
            msg <- c(msg, paste0('uROI columns should be \"rtMin\", \"rt\", ',
                            '\"rtMax\", \"mzMin\", \"mz\", \"mzMax\", not ',
                            paste(colnames(object@uROI), collapse = " ")))
        } else {
            vcheck <- valid_ppR_uROI_content(object, valid, msg, nbCpd)
            valid <- vcheck$valid; msg <- vcheck$msg
        }
    }
    return(list(valid=valid, msg=msg))
}
# check NA and column types, split due to function length
valid_ppR_uROI_content <- function(object, valid, msg, nbCpd){
    # Missing rtMin, rtMax, mzMin or mzMax
    if (object@uROIExist) {
        # only check uROI if declared as existing
        if (any(is.na(object@uROI[,c("rtMin","rtMax","mzMin","mzMax")]))) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$rtMin, uROI$rtMax, uROI$mzMin and ",
                                "uROI$mzMax cannot be NA")) }
    }
    # uROI column type
    if (nbCpd >= 1) {
        if (!is.numeric(object@uROI$rtMin[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$rtMin should be numeric, not ",
                                typeof(object@uROI$rtMin[1]))) }
        if (!is.numeric(object@uROI$rt[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$rt should be numeric, not ",
                                typeof(object@uROI$rt[1]))) }
        if (!is.numeric(object@uROI$rtMax[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$rtMax should be numeric, not ",
                                typeof(object@uROI$rtMax[1]))) }
        if (!is.numeric(object@uROI$mzMin[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$mzMin should be numeric, not ",
                                typeof(object@uROI$mzMin[1]))) }
        if (!is.numeric(object@uROI$mz[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$mz should be numeric, not ",
                                typeof(object@uROI$mz[1]))) }
        if (!is.numeric(object@uROI$mzMax[1])) {
            valid <- FALSE
            msg <- c(msg, paste0("uROI$mzMax should be numeric, not ",
                                typeof(object@uROI$mzMax[1]))) }}
    return(list(valid=valid, msg=msg))
}

## cpdMetadata
valid_ppR_cpdMetadata <- function(object, valid, msg, nbCpd) {
    # number of compounds (rows) in cpdMetadata
    if (dim(object@cpdMetadata)[1] != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("cpdMetadata has ", dim(object@cpdMetadata)[1],
                            " rows (compounds). Should be ", nbCpd)) }
    return(list(valid=valid, msg=msg))
}

## spectraMetadata
valid_ppR_spectraMetadata <- function(object, valid, msg, nbSample) {
    # number of spectra (rows) in spectraMetadata
    if (dim(object@spectraMetadata)[1] != nbSample) {
        valid <- FALSE
        msg <- c(msg, paste0("spectraMetadata has ",
                            dim(object@spectraMetadata)[1],
                            " rows (spectra). Should be ", nbSample)) }
    return(list(valid=valid, msg=msg))
}

## acquisitionTime
valid_ppR_acquisitionTime <- function(object, valid, msg, nbSample) {
    # number of acquisitionTime
    if (length(object@acquisitionTime) != nbSample) {
        valid <- FALSE
        msg <- c(msg, paste0("acquisitionTime has ",
            length(object@acquisitionTime), " elements (samples). Should be ",
            nbSample)) }
    return(list(valid=valid, msg=msg))
}

## useUROI & uROIExist
valid_ppR_useUROIuROIExist <- function(object, valid, msg) {
    # cannot useUROI if uROIExist=FALSE
    if (object@useUROI & !(object@uROIExist)) {
        valid <- FALSE
        msg <- c(msg, paste0("useUROI cannot be TRUE while uROIExist is FALSE"))
    }
    return(list(valid=valid, msg=msg))
}

## TIC
valid_ppR_TIC <- function(object, valid, msg, nbSample) {
    # number of TIC
    if (length(object@TIC) != nbSample) {
        valid <- FALSE
        msg <- c(msg, paste0("TIC has ", length(object@TIC),
                            " elements (samples). Should be ", nbSample)) }
    return(list(valid=valid, msg=msg))
}

## peakTables (nb, type, nb of rows, nb columns, column names)
valid_ppR_peakTables <- function(object, valid, msg, nbCpd, nbSample) {
    # number of peakTables
    if (length(object@peakTables) != nbSample) { valid <- FALSE
        msg <- c(msg, paste0("peakTables has ", length(object@peakTables),
                            " elements (samples). Should be ", nbSample))
    } else { # only check peakTables if min 1 sample and not NULL
        if (nbSample >= 1) { # if ALL peakTables are not NULL
            peakTables_isNULL <- vapply(object@peakTables, is.null,
                                        FUN.VALUE = logical(1))
            if (!all(peakTables_isNULL)) {
                # if one peakTable is NULL but not all, raise an error
                if (any(peakTables_isNULL)) { valid <- FALSE
                    msg <- c(msg, paste0('peakTables must all either be ',
                                        'data.frame or NULL'))
                } else { # individual peakTable is data.frame
                    if (!is.data.frame(object@peakTables[[1]])) { valid <- FALSE
                        msg <- c(msg, paste0('peakTables must be data.frame or',
                                ' NULL not ', typeof(object@peakTables[[1]])))
                    } else { # individual peakTable data.frame number of rows
                        if (dim(object@peakTables[[1]])[1] != nbCpd) {
                            valid <- FALSE
                            msg <- c(msg, paste0("peakTables[[1]] has ",
                                            dim(object@peakTables[[1]])[1],
                                    " rows (compounds). Should be ", nbCpd))}
                        # individual peakTable data.frame number of columns
                        if (dim(object@peakTables[[1]])[2] != 16) {
                            valid <- FALSE
                            msg <- c(msg, paste0("peakTables[[1]] has ",
                                                dim(object@peakTables[[1]])[2],
                                                " columns. Should be 16"))
                        } else { # individual peakTable data.frame column names
                            if (!all(colnames(object@peakTables[[1]]) %in%
                            c("found", "rt", "rtMin", "rtMax", "mz", "mzMin",
                            "mzMax", "peakArea","peakAreaRaw", "maxIntMeasured",
                            "maxIntPredicted", "is_filled", "ppm_error",
                            "rt_dev_sec", "tailingFactor", "asymmetryFactor"))){
                                valid <- FALSE
                                msg <- c(msg, paste0("peakTables[[1]] columns ",
                                    "should be 'found', 'rt', 'rtMin', ",
                                    "'rtMax', 'mz', 'mzMin', 'mzMax', ",
                                    "'peakArea', 'peakAreaRaw', ",
                                    "'maxIntMeasured', ",
                                    "'maxIntPredicted', 'is_filled', ",
                                    "'ppm_error', 'rt_dev_sec', ",
                                    "'tailingFactor', 'asymmetryFactor', not ",
                                    paste(colnames(object@peakTables[[1]]),
                                    collapse = " "))) }}}}}}}
    return(list(valid=valid, msg=msg)) }

## dataPoints (nb, type, nb of rows, nb columns, column names)
valid_ppR_dataPoints <- function(object, valid, msg, nbCpd, nbSample) {
    # number of dataPoints
    if (length(object@dataPoints) != nbSample) {
        valid <- FALSE
        msg <- c(msg, paste0("dataPoints has ", length(object@dataPoints),
                            " elements (samples). Should be ", nbSample))
    } else { # only check dataPoints if min 1 sample and not NULL
        if (nbSample >= 1) { # if ALL dataPoints are not NULL
            dataPoints_isNULL <- vapply(object@dataPoints, is.null,
                                        FUN.VALUE = logical(1))
            if (!all(dataPoints_isNULL)) {
                # if one dataPoints is NULL but not all, raise an error
                if (any(dataPoints_isNULL)) {
                    valid <- FALSE
                    msg <- c(msg, paste0("dataPoints must all either be list ",
                                        "of ROI data points or NULL"))
                } else { # individual dataPoints is list
                    if (!(is.list(object@dataPoints[[1]]))) {
                        valid <- FALSE
                        msg <- c(msg, paste0("dataPoints[[1]] must be a list ",
                            "of ROI data points, not ",paste(class(
                            object@dataPoints[[1]]), collapse = " ")))
                    } else {
                        # check content of dataPoints list
                        ccheck <- valid_ppR_dataPoints_content(object, valid,
                                                                msg, nbCpd)
                        valid <- ccheck$valid; msg <- ccheck$msg
                    }
                }
            }
        }
    }
    return(list(valid=valid, msg=msg))
}
## dataPoints exist, check content
valid_ppR_dataPoints_content <- function(object, valid, msg, nbCpd) {
    # individual dataPoints has entry for each compound(ROI)
    if (length(object@dataPoints[[1]]) != nbCpd) {
        valid <- FALSE
        msg <- c(msg, paste0("dataPoints[[1]] contains, ",
                length(object@dataPoints[[1]]),
                " dataPoints (compound). Should be ",nbCpd))
    } else {
        if (nbCpd >= 1) { # ind dtPts compound entry is df
            if (!is.data.frame(object@dataPoints[[1]][[1]]))
            {
                valid <- FALSE
                msg <- c(msg, paste0("dataPoints[[1]][[1]]",
                            " must be a data.frame, not ",
                        class(object@dataPoints[[1]][[1]])))
            } else {# ind peakTable df nb of columns
                if (dim(object@dataPoints[[1]][[1]])[2]!=3){
                    valid <- FALSE
                    msg <- c(msg,
                        paste0("dataPoints[[1]][[1]] has ",
                        dim(object@dataPoints[[1]][[1]])[2],
                        " columns. Should be 3"))
                } else {
                # individual peakTable dt.frame column names
                    if (!all(colnames(
                        object@dataPoints[[1]][[1]]) %in%
                        c("rt", "mz", "int"))) {
                        valid <- FALSE
                        msg <- c(msg,
                            paste0("dataPoints[[1]][[1]] ",
                            "columns should be 'rt', 'mz',",
                            " 'int', not ", paste(colnames(
                            object@dataPoints[[1]][[1]]),
                            collapse = " ")))
                    }
                }
            }
        }
    }
    return(list(valid=valid, msg=msg))
}

## peakFit (nb, type, nb of rows, nb columns, column names)
valid_ppR_peakFit <- function(object, valid, msg, nbCpd, nbSample) {
    # number of peakFit
    if (length(object@peakFit) != nbSample) {
        valid <- FALSE
        msg <- c(msg, paste0("peakFit has ", length(object@peakFit),
                " elements (samples). Should be ", nbSample))
    } else { # only check peakFit if min 1 sample and not NULL
        if (nbSample >= 1) { # if ALL peakFit are not NULL
            peakFit_isNULL <- vapply(object@peakFit, is.null,
                                    FUN.VALUE = logical(1))
            if (!all(peakFit_isNULL)) {
                # if one peakFit is NULL but not all, raise an error
                if (any(peakFit_isNULL)) {
                    valid <- FALSE
                    msg <- c(msg, paste0("peakFit must all either be list of ",
                                        "ROI curveFit or NULL"))
                } else { # individual peakFit is list
                    if (!(is.list(object@peakFit[[1]]))) {
                        valid <- FALSE
                        msg <- c(msg, paste0("peakFit[[1]] must be a list of ",
                                            "ROI curveFit or NA, not ",
                                            paste(class(object@peakFit[[1]]),
                                                collapse = " ")))
                    } else {
                        # individual peakFit has entry for each compound (ROI)
                        if (length(object@peakFit[[1]]) != nbCpd) {
                            valid <- FALSE
                            msg <- c(msg, paste0("peakFit[[1]] contains, ",
                                        length(object@peakFit[[1]]),
                                        " peakPantheR_curveFit or",
                                        " NA (compound). Should be ", nbCpd))
                        } else { # only check peakFit if min 1 compound
                            if (nbCpd >= 1) {
                                # individual peakFit compound entry is
                                # peakPantheR_curveFit or NA
                                if (!all(is.na(object@peakFit[[1]][[1]])) &
                                    !is.peakPantheR_curveFit(
                                        object@peakFit[[1]][[1]])){
                                    valid <- FALSE
                                    msg <- c(msg, paste0("peakFit[[1]][[1]] ",
                                        "must be NA or a peakPantheR_curveFit,",
                                        " not ",
                                        class(object@peakFit[[1]][[1]])))
                                }}}}}}}}
    return(list(valid=valid, msg=msg))
}