mkdir combinedBigwig
 
# cp /bgfs/karndt/Annotations/BED_files/* bedFiles

# generates a cutoff version of the sample name for combining files, also cuts off a trailing underscore if present
# awk -F '[1/2]' '{print $1}' sampleIDs.txt | sed 's/_$//' | uniq > sampleIDsTrunc.txt
# cat sampleIDsTrunc.txt

# Averages bigwig files of replicates while preserving sense 
# !!! may require manual intervention to make sure samples combine well w/o errors !!! 
parallel --header : bigwigCompare -b1 bigwig/{SAMPLE}*1_S*{STRAND}.bw -b2 bigwig/{SAMPLE}*2_S*{STRAND}.bw \
	--operation mean -o combinedBigwig/{SAMPLE}_{STRAND}.bw --binSize 1 :::: sampleIDsTrunc.txt ::: 'STRAND' fwd rev
