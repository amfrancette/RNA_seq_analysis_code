mkdir PCA 

# Summarizes read density by bin for all included bws 
multiBigwigSummary BED-file \
	--bwfiles bigwig/WH*.bw bigwig/T45*.bw bigwig/R52*.bw \
	--BED /bgfs/karndt/Annotations/BED_files/plus1nuc_CDS_CPS.sorted.bed \
	--outRawCounts countMatrix/AEH_mRNA_countMatrix \
	-out AEH_mRNA_Summary.npz 
	
	plotPCA \
	-in AEH_mRNA_Summary.npz \
	--plotFile PCA/AEH_mRNA_PCA.png

plotCorrelation \
	-in AEH_mRNA_Summary.npz \
	--corMethod pearson --skipZeros \
	--plotTitle "Pearson Correlation of Average Scores Per Transcript" \
	--whatToPlot scatterplot \
	--removeOutliers \
	--log1p \
	-o correlationPlot/AEH_mRNA_scatterplot_PearsonCorr_bigwigScores.png   \
	--outFileCorMatrix correlationPlot/AEH_mRNA_PearsonCorr_bigwigScores.tab

plotCorrelation \
	-in AEH_mRNA_Summary.npz \
	--corMethod pearson --skipZeros \
	--plotTitle "Pearson Correlation of Average Scores Per Transcript" \
	--whatToPlot heatmap \
	--removeOutliers \
	--zMin 0.7 \
	--plotNumbers \
	-o correlationPlot/AEH_mRNA_heatmap_PearsonCorr_bigwigScores.png   \
	--outFileCorMatrix w.tab
