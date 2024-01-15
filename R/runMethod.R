

runMethodBoundingBoxes <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("BoundingBoxes", "Run"))

  maskFilePath <- opts$maskFilePath

  outFilePath <- paste0(
    stringr::str_sub(maskFilePath, end=-4),
    "_boundingBox.nc")

  pt <- proc.time()
  boundingBoxes <- ProcessNetCdf::getBoundingBoxesFromMask(maskFilePath)
  cat("obtained", ncol(boundingBoxes), "bounding boxes in ", (proc.time()-pt)[3],"s\n")
  cat("saving bounding boxes to file ", outFilePath, "... ")
  ProcessNetCdf::saveBoundingBoxes(
    boundingBoxes,
    outFilePath,
    maskFilePath,
    regionVariableName = "regionName")
  cat("done.\n")
}


runMethodSumMask <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("SumMask", "Run"))

  ProcessNetCdf::setupMaskSummation(
    maskFilePath = opts$maskFilePath,
    outFilePath = opts$outFilePath
  )

  ProcessNetCdf::runMaskSummation()
}


runMethodSumAggregation <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("SumAggregation", "Run"))

  ProcessNetCdf::setupSumAggregation(
    targetFormat = opts$targetFormat,
    maskFilePath = opts$maskFilePath,
    maskSumFilePath = opts$maskSumFilePath,
    boundingBoxFilePath = opts$boundingBoxFilePath,
    variableDataDescriptor = opts$variableDataDescriptor,
    outFilePath = opts$outFilePath
  )

  ProcessNetCdf::runSumAggregation(opts$yearsFilter, opts$regionIndices)
}


runMethodShapeToMask <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("ShapeToMask", "Run"))

  subclass <- ConfigOpts::getClassAt(opts, 3)

  switch(
    subclass,
    OneFilePerRegion = runMethodShapeToMaskOneFilePerRegion(opts),
    OneFileForAllRegions = runMethodShapeToMaskOneFileForAllRegions(opts),
    stop("Unknown subclass: ", subclass)
  )
}


runMethodShapeToMaskOneFilePerRegion <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("OneFilePerRegion", "ShapeToMask", "Run"))

  filePaths <- list.files(opts$shapeFileDir, full.names = TRUE, recursive=TRUE)
  shapeFilePaths <- stringr::str_subset(filePaths, opts$shapeFilePattern)
  names(shapeFilePaths) <- uniqueMiddle(shapeFilePaths)

  cat("Found", length(shapeFilePaths), "shape files.\n")

  ProcessNetCdf::runShapeToMaskOneFilePerRegion(
    shapeFilePaths = shapeFilePaths,
    nLon = opts$nLon,
    nLat = opts$nLat,
    outFilePath = opts$outFilePath
  )
}


runMethodShapeToMaskOneFileForAllRegions <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("OneFileForAllRegions", "ShapeToMask", "Run"))

  if (opts$slurm$jobIdx > 1) {
    metaOutFilePath <- NULL
  } else {
    metaOutFilePath <- opts$metaOutFilePath
  }

  ProcessNetCdf::runShapeToMaskOneFileForAllRegions(
    shapeFilePath = opts$shapeFilePath,
    nLon = opts$nLon,
    nLat = opts$nLat,
    outFilePrefix = opts$outFilePrefix,
    metaOutFilePath = metaOutFilePath,
    idColumnName = opts$idColumnName,
    nBatches = opts$slurm$nJobs,
    batchIndexFilter = opts$slurm$jobIdx
  )
}


runMethodConcatNetCdf <- function(opts) {

  opts <- ConfigOpts::asOpts(opts, c("ConcatNetCdf", "Run"))

  ProcessNetCdf::runConcatNetCdf(
    outFilePath = opts$outFilePath,
    inFileDir = opts$inFileDir,
    inFilePattern = opts$inFilePattern
  )

}

