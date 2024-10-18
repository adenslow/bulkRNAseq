library("Rsamtools")
library("ShortRead")
library("GenomicRanges")
library("GenomicFeatures")
library("GenomicAlignments")
library("Cairo")

experimentName=Sys.getenv("experiment_name")
genome=Sys.getenv("genome")

cutoffRPM=Sys.getenv("RPMcutoff")
fqDir=Sys.getenv("fqDir")

#manifest should have at least these columns: fileRoot, group, bamFile, dir
sampleManifest=Sys.getenv("sampleManifest")

setwd(fqDir)


source("/home/adenslow/scripts/Rscripts/RNAseq_processing/GeneCountsSource.R")



fqFile=paste0(fqDir, sampleManifest)
print(paste0("Sample manifest path:", fqFile))
files=read.csv(paste0(fqFile), sep = ",", header = T, row.names=1)

files=files[order(files$group),]



tx = select_ref_txdb(genome)
org = select_ref_org(genome)

print("Set up exon and gene tables for annotation of reads")
exons = exonsBy(tx, by = "gene")
print("Head(exons)")
head(exons)

geneCts = matrix(0, ncol = nrow(files), nrow = length(exons), dimnames = list(names(exons), files$fileRoot))
print("Head(geneCts)")
head(geneCts)

# Create a parameter object
print("Create a parameter object")
sbp = ScanBamParam(flag = scanBamFlag(isDuplicate = F))

for (i in 1:nrow(files)) {

  print(paste(files$fileRoot[i], Sys.time()))

  si = seqinfo(BamFile(paste0(files$dir[i], files$bamFile[i])))

  # Read in paired alignmentR
  reads = readGAlignmentPairs(paste0(files$dir[i], files$bamFile[i]), param = sbp)

  # Get counts
  so = summarizeOverlaps(exons, reads, mode = "IntersectionNotEmpty", singleEnd = F, ignore.strand = T)
  cts = assays(so)$counts

  geneCts[rownames(cts), files$fileRoot[i]] = cts
}

# Since the important work is done, make sure we don't lose it
print("Checkpoint ... saving")

save.image("checkpoint.coverage.RData")
#org = select_ref_org(genome) # Needs to be done again if loading from image

print("Get gene symbol from ENTREZID id row names # TODO: Remove references to ENTREZIDs")
geneSym = select(org, columns = "SYMBOL", keytype = "ENTREZID", keys = row.names(geneCts))
geneCts = cbind(geneSym, geneCts)
print("Head of geneCts without exon info:")

head(geneCts)
# Add gene length info
geneCts$length = sum(width(exons))

# Save unfiltered gene counts matrix
print("Save unfiltered gene counts matrix")
write.table(geneCts, file = paste0(experimentName, ".geneCts.exon.txt"), sep = "\t", quote = F, row.names = F)

print("Head of geneCts:")
head(geneCts)
# Perform normalization
print("Perform normalization")
# Split cts into its two components
ctsMatrix = geneCts[,  names(geneCts) %in% files$fileRoot]
geneInfo  = geneCts[, !names(geneCts) %in% files$fileRoot]

print("RPM normalized gene counts")
# RPM normalized gene counts; RPM = geneReads * 1e6 / uniqueReads
geneRpm = t(t(ctsMatrix) * 1e6 / colSums(ctsMatrix))
geneRpm = round(geneRpm, 3)
colnames(geneRpm) = paste0(files$fileRoot, ".rpm")
geneRpmAnnotated = cbind(geneInfo, geneRpm)

# Reads Per Kilobase of transcript Per Million mapped reads (RPKM) normalized gene counts
# RPKM = RPM * 1000 / gene_length = (geneReads * 1e9) / (uniqueReads * gene_length)
geneRpkm = (geneRpm * 1000)/ geneCts$length
geneRpkm = round(geneRpkm, 3)
colnames(geneRpkm) = paste0(files$fileRoot, ".rpkm")
geneRpkmAnnotated = cbind(geneInfo, geneRpkm)


# Possible RPM cutoffs for plotting
print("Possible RPM cutoffs for plotting")
rpm10 = log2(10+0.01)
rpm5 = log2(5+0.01)
rpm3 = log2(3+0.01)

#print("Generating pdf")
#pdf(file = paste0(experimentName, ".Transcript.Density.plot.pdf"), height = 5, width = 5)
#       par(mai = c(1.5, 0.75, 0.75, 0.25), mgp = c(2, 0.5, 0), family = "Helvetica")
#       plot(NA, ylim = c(0, 0.2), xlim = c(-10,15), xlab = "log2 RPM+0.01", ylab = "density")
#       lines(c(rpm10, rpm10), c(0, 0.2), lty = 2, col = "blue", lwd = 1)
#       lines(c(rpm5, rpm5), c(0, 0.2), lty = 2, col = "blue", lwd = 1)
#       lines(c(rpm3, rpm3), c(0, 0.2), lty = 2, col = "blue", lwd = 1)
        # Annotate the 3 cutoff lines
#       text(rpm10+0.8, 0.15, labels = "10", col = "blue", cex = 0.8)
#       text(rpm5+0.5, 0.12, labels = "5", col = "blue", cex = 0.8)
#       text(rpm3-0.5, 0.11, labels = "3", col = "blue", cex = 0.8)
#       for(i in 1:ncol(geneRpm)) {
#               lines(density(log2(geneRpm[,i]+0.01)), lwd = 0.2)
#       }
#dev.off()

# Filter genes based on a group RPM threshold
print("Filter genes based on a group RPM threshold")
ctsName  = paste0(experimentName, ".geneCts.detected.RPM.",  cutoffRPM, ".exon.txt")
rpmName  = paste0(experimentName, ".geneRpm.detected.RPM.",  cutoffRPM, ".exon.txt")
rpkmName = paste0(experimentName, ".geneRpkm.detected.RPM.", cutoffRPM, ".exon.txt")

detected = apply(geneRpm, 1, function(x) filter_detected(x, files$group, cutoffRPM))

write.table(geneCts[detected, ], file = ctsName, sep = "\t", quote = F, row.names = F)
write.table(geneRpmAnnotated[detected, ],  file = rpmName,  sep = "\t", quote = F, row.names = F)
write.table(geneRpkmAnnotated[detected, ], file = rpkmName, sep = "\t", quote = F, row.names = F)

print("Capturing output")
capture.output(sessionInfo(), file = paste0("Rsession.Info.", experimentName, ".", gsub("\\D", "", Sys.time()), ".txt"))


print("Done!")
