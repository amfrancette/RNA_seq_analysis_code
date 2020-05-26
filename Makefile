# show invisible characters to troubleshoot formating errors in Makefile with cat -e -t -v  mk.t
# NOTE Make language is slightly different than bash 
# Notably you will need $$ instead of $ in most cases and indents matter greatly

# To successfully execute the Makefile keep the Makefile, src folder, and bedFiles folder in the project directory

# SET STARTING PARAMETERS HERE FOR SRAProject, Fastq folder location, and index files
SRAProj:=PRJNA381711
export SRAProj

while getopts c:f:i:s:r: option
do
case "${option}"
in
c) dir:=${OPTARG};;
f) fastq_dir:=${OPTARG};;
i) sample_index:=${OPTARG};;
s) spike_in_hisat2_index:=${OPTARG};;
r) sac_cer_hisat2_index:=${OPTARG};;
esac
done
echo ${dir}

# specify folder with fastqFiles used in analysis, this is VERY IMPORTANT to build sample IDs
fastqFolder:=../fastq_test/fastq_6M
#fastqFolder:=SRA/${SRAProj}
export fastqFolder

# specify HISAT index files for alignment, if necessary
sacCer3Index:=/bgfs/karndt/Indexes/HISAT2_S_cerevisiae/genome_tran
export sacCer3Index
pombeIndex:=/bgfs/karndt/Indexes/HISAT2_S_pombe/s_pom_tran
export pombeIndex
kanmxIndex:=/bgfs/karndt/Indexes/HISAT2_KanMX/KanMx
export kanmxIndex

# specify gtf file for featureCounts 
gtfFile:=/bgfs/karndt/Annotations/featureCounts/combined.gtf
export gtfFile

# specify bed file folder for heatmap generation
bedFolder:=bedFiles
export bedFolder 

#help:  @List available tasks on this project
help: 
	@echo ">--------------------------------------------------------------------------------------------------------------------------------------------------<"
	@echo "This makefile will execute alignment, spike-in normalization, and perform several analysis steps see tools below for more detail. To execute a rule simply write:"
	@echo "Be sure to check the src scripts to tweak or customize the pipeline further."
	@echo ""
	@echo "make [insertrule]"
	@echo ""
	@echo "The rules:"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| sort | tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "fastqFolder is currently: "${fastqFolder}
	@echo ${-e specifiedFolder}
	@echo $$specifiedFolder
	@echo 
	@echo  "sacCer3Index is located: "${sacCer3Index} 
	@echo  "pombeIndex is located: "${spombeIndex} 
	@echo ">--------------------------------------------------------------------------------------------------------------------------------------------------<"

#sampleIDs: @ lists sample ids as the names of fastq files up to "_[R1/R2]_". Change if necessary. 
sampleIDs: 
	echo $$SRAProj
	echo $$fastqFolder
	-@rm sampleIDs.txt
	-@rm sampleIDsDifference.txt
	-@rm bedFileIDs.txt
	@echo SAMPLE > sampleIDs.txt 
	@echo SAMPLE > sampleIDsDifference.txt 
	@echo BEDFILE > bedFileIDs.txt
	@echo ""
	@for fastq_file in `ls ${fastqFolder}/*.fastq | awk -F '_R1_' '{print $$1}' | awk -F '_R2_' '{print $$1}' | awk -F '/' '{print $$(NF)}'  |  sort | uniq`; do \
		echo $$fastq_file >> sampleIDs.txt; \
	done
	
	@echo "sample IDs (in three columns) are:" 
	@cat sampleIDs.txt | paste -d"|||" - - -
	@echo ""
	
	@echo "sample IDs of combined reps (made with bigwigCombine) are:" 
	@cat sampleIDsTrunc.txt | paste -d"|||" - - -
	@echo ""
	
	@echo "sample IDs of difference bigwigs (made with bigwigCompare) are:" 
	-@ls differenceBigwig/*.bw | awk -F '[./]' '{print $$2}' |  awk -F '_' '{print $$(NF-1)}' | sort | uniq >> sampleIDsDifference.txt 
	@cat sampleIDsDifference.txt | paste -d"|||" - - 
	@echo ""
	
	@echo "bed files are:" 
	@ls ${bedFolder} | awk -F '.' '{print $$1}' >> bedFileIDs.txt
	@cat bedFileIDs.txt | paste -d"|||" - - 
	@echo ""
	

#alignment: @ Uses HISAT2 to align reads to reference genome (default SacCer3)
alignment:
	# bash src/HISAT2_alignment.sh
	bash src/HISAT2_alignmentWithSpikein.sh
	

#fetchSRA: @ downloads the contents of an SRA project. Please specify project PRJ # in the makefile
fetchSRA:
	bash src/fetchSRA.sh
	

#normalizedBigwig: @ generates RPKM normalized bigwig files
normalizedBigwig:
	# bash src/RPKMNormalizedBigwig.sh
	bash src/spikeinNormalizedBigwigICPM.sh
	

#fCounts: @ generates count file with featurecounts from the subread toolkit
fCounts:
	bash src/featureCounts.sh
	

#combinedBigwig: @ merges bigwigs of different Reps using deeptools bigwigCompare
combinedBigwig:
	bash src/bigwigCombine.sh
	
	
#log2fcBigwig: @ merges bigwigs of different Reps using deeptools bigwigCompare
log2fcBigwig:
	bash src/bigwigCompare.sh
	

#generatePCA: @ merges bigwigs of different Reps using deeptools bigwigCompare
generatePCA:
	bash src/generatePCA.sh
	

#heatmaps: @ merges bigwigs of different Reps using deeptools bigwigCompare
heatmaps:
	bash src/generateHeatmaps.sh
	
	


# # this will subsample 20,000 random reads from fastq files
# for fastq_file in `ls fastq/*_R1_001.fastq | awk -F '[_/]' '{print $2 "_" $3 "_" $4}'`
# do 
# 	echo $fastq_file
#  	seqtk sample -s100 fastq/"$fastq_file"*R1*.fastq 2000000 > test1/fastq/"$fastq_file"_R1_001.fastq
#  	seqtk sample -s100 fastq/"$fastq_file"*R3*.fastq 2000000 > test1/fastq/"$fastq_file"_R2_001.fastq
# done 