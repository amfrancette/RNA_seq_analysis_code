mkdir sam
mkdir unmappedfastq
mkdir pombeBam
mkdir bam
mkdir pombeAlignmentStats
mkdir sacCerAlignmentStats
mkdir kanmx_alignment_stats

echo $pombeIndex
echo $sacCer3Index

## PARAMETER JUSTIFICATION 
	# hisat2 parameters are set to use 8 threads (-p), execute quietly (-q), 
	# search for no more than 2 unique alignments (-K), accept inserts no greater than 1000 bp (-X)
	# ignore unaligned reads, (--no-unal), only accept introns within the bounds of those already known
	# (--max/min-intronlen [bounds were extracted from ARES Yeast Intron Database 4.1 2011]),
	# report the time for the alignment (-t), save reads that do not align concordantly 
	# to pombe genome in the unmappedfastq folder (--un-conc) 
	
	# Reads will map to KanMX index if the strain is expressing the KANMX marker
	# Reads mapping to pombe will be used for spike-in normalization


## loops through fastq files in the "fastq" directory and executes hisat alignment
## awk command cuts and reprints filename before "_R1_001" or "_R2_001"
## echo commands are for troubleshooting

# mapping spike in reads and subtracts every pombe mapping read from the fastq
# resultant unmapped fastq file contains everything not mapping to S. pombe

# !!! Note that naming scheme of sampleIDs.txt is maintained throughout the rest 
# of the analysis it is possible to rename the output with another IDs file in the
# same sample order. It must be linked to the original sampleIDs file with ::::+ 
# and will need a different header name !!!

echo $fastqFolder
parallel --header : hisat2 \
	-p 8 \
	-q \
	--no-mixed \
	--no-discordant \
	-k 2 \
	--trim5 16 \
	-X 1000 \
	--no-unal \
	--min-intronlen 52 \
	--max-intronlen 1002 \
	-t \
	-x "$pombeIndex" \
	-1 "$fastqFolder"/{SAMPLE}_R1_001.fastq \
	-2 "$fastqFolder"/{SAMPLE}_R2_001.fastq \
	--un-conc unmappedfastq/{SAMPLE}_unmapped_R%.fastq \
	-S sam/{SAMPLE}_pombe.sam \
	--summary-file pombeAlignmentStats/{SAMPLE}_pombeAlignmentSummary.txt :::: sampleIDs.txt

echo pombe mapped 

echo samtools start

# converts sam to bam
parallel --header : samtools view -bS -q10 sam/{SAMPLE}_pombe.sam '>' \
pombeBam/{SAMPLE}_pombe.bam :::: sampleIDs.txt 

# sorts bam file
parallel --header : samtools sort -T pombeBam/{SAMPLE}_pombe.sorted \
-o pombeBam/{SAMPLE}_pombe.sorted.bam \
pombeBam/{SAMPLE}_pombe.bam :::: sampleIDs.txt 

# generates bai
parallel --header : samtools index pombeBam/{SAMPLE}_pombe.sorted.bam :::: sampleIDs.txt 

rm sam/*.sam
parallel --header : rm pombeBam/{}_pombe.bam :::: sampleIDs.txt

echo pombe bam created, mapping unmapped reads to sacCer3

# mapping to SacCer3
parallel --header : hisat2 \
	-p 8 \
	-q \
	--no-mixed \
	--no-discordant \
	-k 2 \
	-X 1000 \
	--no-unal \
	--min-intronlen 52 \
	--max-intronlen 1002 \
	-t \
	-x "$sacCer3Index" \
	-1 unmappedfastq/{SAMPLE}_unmapped_R1.fastq \
	-2 unmappedfastq/{SAMPLE}_unmapped_R2.fastq \
	-S sam/{SAMPLE}.sam \
	--summary-file sacCerAlignmentStats/{SAMPLE}.txt \
	:::: sampleIDs.txt

parallel --header : samtools view -bS -q10 sam/{SAMPLE}.sam '>' \
bam/{SAMPLE}.bam :::: sampleIDs.txt

parallel --header : samtools sort -T bam/{SAMPLE}.sorted \
-o bam/{SAMPLE}.sorted.bam \
bam/{SAMPLE}.bam :::: sampleIDs.txt

parallel --header : samtools index bam/{SAMPLE}.sorted.bam :::: sampleIDs.txt

rm sam/*.sam 
parallel --header : rm bam/{}.bam :::: sampleIDs.txt

echo sacCer3 mapped

exit


