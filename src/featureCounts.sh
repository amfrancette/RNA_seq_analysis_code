
mkdir featureCountsRes

# -a annotation file, -F specifies GTF format, -t specifies feature type to count, -p paired-end
rm featureCountsRes/featureList
echo FEATURE > featureCountsRes/featureList
echo mRNA >> featureCountsRes/featureList
echo snoRNA >> featureCountsRes/featureList
cat featureCountsRes/featureList

head "$annotFile_gtf"

parallel --header : featureCounts \
	-a "$annotFile_gtf" \
	-F 'GTF' \
	-p \
	-t {FEATURE} \
	-o featureCountsRes/counts_{FEATURE} \
	`ls bam/*.sorted.bam` :::: featureCountsRes/featureList

exit