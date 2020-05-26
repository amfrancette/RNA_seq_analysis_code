mkdir bigwig 

echo ICPM > ICPMs.txt
parallel --header : --keep-order bamtools count -in pombeBam/{SAMPLE}_pombe.sorted.bam :::: sampleIDs.txt | awk '{print (1/($1/100000))}' >> ICPMs.txt
cat ICPMs.txt 
	
parallel --header : bamCoverage \
	--bam bam/{SAMPLE}.sorted.bam \
	--outFileName bigwig/{SAMPLE}.bw \
	--outFileFormat bigwig \
	--scaleFactor {ICPM} \
	--binSize 1 :::: sampleIDs.txt ::::+ ICPMs.txt
	
parallel --header : bamCoverage \
	--bam bam/{SAMPLE}.sorted.bam \
	--outFileName bigwig/{SAMPLE}_fwd.bw \
	--outFileFormat bigwig \
	--filterRNAstrand reverse \
	--scaleFactor {ICPM} \
	--binSize 1 :::: sampleIDs.txt ::::+ ICPMs.txt
	
parallel --header : bamCoverage \
	--bam bam/{SAMPLE}.sorted.bam \
	--outFileName bigwig/{SAMPLE}_rev.bw \
	--outFileFormat bigwig \
	--filterRNAstrand forward \
	--scaleFactor {ICPM} \
	--binSize 1 :::: sampleIDs.txt ::::+ ICPMs.txt

exit
