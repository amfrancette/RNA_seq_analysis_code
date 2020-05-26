mkdir matrix
mkdir heatmap

echo bedFiles are:
cat bedFileIDs.txt 
bigwigFolder=differenceBigwig
mkdir matrix/"$bigwigFolder"_matricies

# # if needed, execute this command to split reference bed files into + and - strands
# 	head "$ano_file"
# mkdir bedFilesStranded
# # needed to use \' to make parallel recognize quotes in awk correctly
# parallel --header :  awk  \' '$6 == "-" {print}' \' bedFiles/{BEDFILE}.sorted.bed '>' bedFilesStranded/{BEDFILE}_minus.bed :::: bedFileIDs.txt
# parallel --header :  awk  \' '$6 == "+" {print}' \' bedFiles/{BEDFILE}.sorted.bed '>' bedFilesStranded/{BEDFILE}_plus.bed :::: bedFileIDs.txt
# 
# # making a file to set heatmap length to be proportional to the length of the annotation file
echo HEIGHT > heatmapHeights.txt
parallel --header : --keep-order wc -l "$bedFolder"/{}.sorted.bed :::: bedFileIDs.txt | awk '{print (($1/100)+1)}' >> heatmapHeights.txt
cat heatmapHeights.txt

# >------SPECIFY MATRICIES TO GENERATE------------<
# computes matrices and plots for AEH data
# TES and TSS centered
echo building TES and TSS matricies
parallel --header : computeMatrix reference-point \
	--referencePoint "{MAPTYPE}" -b 500 -a 500 \
	-S "$bigwigFolder"/*_{STRAND}.bw \
	-R bedFilesStranded/{BEDFILE}_{BED_DIRECTION}.bed \
	--binSize 25 --missingDataAsZero --sortUsing mean --averageTypeBins mean \
	-out matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}_{STRAND}.gz \
	 :::: bedFileIDs.txt ::: 'STRAND' fwd fwd rev rev :::+ 'BED_DIRECTION' plus minus plus minus :::+ 'SENSE' sense antisense antisense sense ::: 'MAPTYPE' TSS TES

#Whole gene starting at TSS
echo building wholegene matricies
parallel --header : computeMatrix reference-point \
	--referencePoint "TSS" -b 500 -a 5000 \
	-S "$bigwigFolder"/*_{STRAND}.bw \
	-R bedFilesStranded/{BEDFILE}_{BED_DIRECTION}.bed \
	--binSize 25 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_wholegene_{STRAND}.gz \
	:::: bedFileIDs.txt ::: 'STRAND' fwd fwd rev rev :::+ 'BED_DIRECTION' plus minus plus minus :::+ 'SENSE' sense antisense antisense sense

#scaled over feature +/- 500 bp
echo building scaled500 matricies
parallel --header : computeMatrix scale-regions \
	-S "$bigwigFolder"/*_{STRAND}.bw \
	-R bedFilesStranded/{BEDFILE}_{BED_DIRECTION}.bed \
	--beforeRegionStartLength 500 \
	--afterRegionStartLength 500 \
	--binSize 25 --missingDataAsZero --sortUsing mean --averageTypeBins mean \
	-out matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_scaled500_{STRAND}.gz \
	:::: bedFileIDs.txt ::: 'STRAND' fwd fwd rev rev :::+ 'BED_DIRECTION' plus minus plus minus :::+ 'SENSE' sense antisense antisense sense
	
# Whole gene starting at TSS NAafterend
parallel --header : computeMatrix reference-point \
--referencePoint "TSS" -b 500 -a 5000 \
--nanAfterEnd \
-S "$bigwigFolder"/*_{STRAND}.bw \
	-R bedFilesStranded/{BEDFILE}_{BED_DIRECTION}.bed \
--binSize 25 --missingDataAsZero --sortUsing region_length --averageTypeBins mean \
	-out matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_NaN_{STRAND}.gz \
	:::: bedFileIDs.txt ::: 'STRAND' fwd fwd rev rev :::+ 'BED_DIRECTION' plus minus plus minus :::+ 'SENSE' sense antisense antisense sense

# >------END MATRIX GENERATION------------<

echo start matrix combining
# binds sense plus strand mapping to sense minus strand mapping
parallel --header : computeMatrixOperations rbind \
	-m matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}_fwd.gz \
	matrix/"$bigwigFolder"_matricies/matrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}_rev.gz \
	-o matrix/"$bigwigFolder"_matricies/combMatrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}.gz \
	:::: bedFileIDs.txt ::: 'SENSE' sense antisense ::: 'MAPTYPE' TES TSS NaN wholegene scaled500


# generating heatmap png directory structure to keep things organized
parallel --header : mkdir -p heatmap/{BEDFILE}/{SENSE} \
:::: bedFileIDs.txt ::: 'SENSE' sense antisense

# >----------SPECIFY HEATMAPS TO GENERATE --------------<
# Difference heatmaps (for visualizing log2fc in read density)
echo plotting difference heatmaps
parallel --header : plotHeatmap \
	-m matrix/"$bigwigFolder"_matricies/combMatrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}.gz \
	-out heatmap/{BEDFILE}/{SENSE}/heatmap_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}.png --dpi 300 \
	--sortUsing {SORTUSING} --missingDataColor 1 --sortRegions {SORTREGIONS} \
	--colorMap 'seismic' \
	--whatToShow "'plot, heatmap and colorbar'" \
	--heatmapHeight {HEIGHT} \
	--heatmapWidth 10 \
	--zMin -2 \
	--zMax 2 \
	:::: bedFileIDs.txt ::::+ heatmapHeights.txt \
	::: 'SENSE' sense antisense \
	::: 'MAPTYPE' wholegene TSS TES scaled500 :::+ 'SORTUSING' region_length median median median :::+ 'SORTREGIONS' ascend descend descend descend
	
# # Greys heatmap (for visualizing read density)
# echo plotting greys heatmaps 
# parallel --header : plotHeatmap \
# 	-m matrix/"$bigwigFolder"_matricies/combMatrix_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}.gz \
# 	-out heatmap/{BEDFILE}/{SENSE}/heatmap_"$bigwigFolder"_{BEDFILE}_{SENSE}_{MAPTYPE}_grey.png --dpi 300 \
# 	--sortUsing {SORTUSING} --missingDataColor 1 --sortRegions {SORTREGIONS} \
# 	--colorMap 'Greys' \
# 	--whatToShow "'plot, heatmap and colorbar'" \
# 	--heatmapHeight {HEIGHT} \
# 	--heatmapWidth 10 \
# 	:::: bedFileIDs.txt ::::+ heatmapHeights.txt \
# 	::: 'SENSE' sense antisense \
# 	::: 'MAPTYPE' wholegene TSS TES scaled500 NaN :::+ 'SORTUSING' region_length median median median :::+ 'SORTREGIONS' ascend descend descend descend
	
 rm matrix/"$bigwigFolder"_matricies/matrix_*.gz
exit
