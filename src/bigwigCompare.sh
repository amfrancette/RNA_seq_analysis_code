mkdir differenceBigwig

# makes log2 dif bigwigs. First input is the reference file and the other is everything else
# can easily modify to specify the control and experimental filenames
parallel --header : bigwigCompare -b1 combinedBigwig/{CONTROL}_{STRAND}.bw -b2 combinedBigwig/{SAMPLE}_{STRAND}.bw \
	--operation log2 -o differenceBigwig/{SAMPLE}vs{CONTROL}_{STRAND}.bw --binSize 1 ::: 'CONTROL' WH3 :::: sampleIDsTrunc.txt ::: 'STRAND' fwd rev
	
	rm differenceBigwig/WH3vsWH3*.bw