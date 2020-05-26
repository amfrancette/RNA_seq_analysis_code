mkdir rpkmbigwig

# normalizing to reads per kilobase mapped
parallel --header : bamCoverage --bam bam/{SAMPLE}.sorted.bam \
	--outFileName rpkmbigwig/{SAMPLE}_rpkm.bw \
	--outFileFormat bigwig \
	--ignoreDuplicates \
	--normalizeUsing RPKM \
	--binSize 1 :::: sampleIDs.txt

exit