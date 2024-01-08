**<font color="grey"><font size=10>UPSTREAM ANALYSIS of ChIP-Seq </font></font>**
<font size=5><font color="grey"><p align="right">2021.08.13</p></font></font>
# <font color="steelblue">Pipe for ChIP-seq </font>

<!-- vscode-markdown-toc -->
* 1. [ <font size=4>1  Quality control (fastQC)</font>](#fontsize41QualitycontrolfastQCfont)
* 2. [ <font size=4>2   Mapping reads(ChIP-seq mappers)</font>](#fontsize42MappingreadsChIP-seqmappersfont)
* 3. [ <font size=4>3  Sorting alignment and converting(samtools)</font>](#fontsize43Sortingalignmentandconvertingsamtoolsfont)
* 4. [ <font size=4>4  Get the unique reads(java or samtools)</font>](#fontsize44Gettheuniquereadsjavaorsamtoolsfont)
* 5. [ <font size=4>5  Make bw files</font>](#fontsize45Makebwfilesfont)
* 6. [ <font size=4>6  Peak calling</font>](#fontsize46Peakcallingfont)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


***    
##  1. <a name='fontsize41QualitycontrolfastQCfont'></a> <font size=4>  Quality control (fastQC)</font>
Get the basic and quality information of the library.Most ChIP-seq data is read long by short, and removing low quality is not necessary. However, if there is a significant decrease in the quality of a large number of bases in FASTQC, it needs to be removed.

```shell
fastqc -o ./fastqc -t 16 ${line}_1.fq.gz ${line}_2.fq.gz #pair end
fastqc -o ./fastqc -t 16 ${line}.fq.gz #single end
```

##  2. <a name='fontsize42MappingreadsChIP-seqmappersfont'></a> <font size=4>   Mapping reads(ChIP-seq mappers)</font>
Using the ChIP-seq mappers , such as <kbd>hisat2</kbd> , <kbd>bowtie</kbd> , <kbd>bowtie2</kbd> , <kbd>STAR</kbd> or another , mapping the reads against the genome reference and identifying their genomic positions.
```shell
# When comparing with bowtie2, 5 bases at the 5' and 10 bases at the 3' were removed, and possible joints and parts with poor quality were removed.
bowtie2 -S ${input}.sam -p 16 -5 5 -3 10 -x /media/hp/disk1/song/Genomes/${species}/Sequences/WholeGenomeFasta/bowtie2/${species} -1 ${line}_1.fq.gz -2 ${line}_2.fq.gz 2>> ../mapping_report.txt
```

##  3. <a name='fontsize43Sortingalignmentandconvertingsamtoolsfont'></a> <font size=4>  Sorting alignment and converting(samtools)</font>
The samtools software converts sam files into bam files. Converting to bam files saves storage space and speeds up processing.
```shell
samtools view -@ 16 -Sb ${line}.sam > ${line}.bam
samtools sort -@ 16 ${line}.bam -o ${line}.sort.bam
```

##  4. <a name='fontsize44Gettheuniquereadsjavaorsamtoolsfont'></a> <font size=4>  Get the unique reads(java or samtools)</font>
```shell
java -jar ~/picard/picard.jar MarkDuplicates I=${line}.sort.bam O=${line}.sort.markdup.bam M=${line}.markdup.txt
```
Creating the index for the bam
```shell
samtools index ${line}.sort.markdup.bam
```

##  5. <a name='fontsize45Makebwfilesfont'></a> <font size=4>  Make bw files</font>
```shell
bamCoverage -p 16 -b ${line}.sort.markdup.bam -o ${line}.bw --binSize 10 --normalizeUsing RPGC --effectiveGenomeSize 	2913022398 --extendReads 200
#effectiveGenomeSize varies from species to species
#Single-ended sequencing needs extendReads parameter
```

##  6. <a name='fontsize46Peakcallingfont'></a> <font size=4>  Peak calling</font>
```shell
macs2 callpeak -t ${line}.bam -c ../wt_input/wt_input.bam -f BAM -g 4.1e8 -q 0.05 --broad --max-gap 500 -n $line

```

##  7. <a name='fontsize46Peakcallingfont'></a> <font size=4>  Deeptools</font>
```shell
computeMatrix scale-regions -S H3K9ac_EV.bw H3K9ac_FS.bw H3K9ac_FL.bw -R /media/hp/disk1/song/Genomes/${species}/Genes/genes.bed --beforeRegionStartLength 1000 --afterRegionStartLength 1000 --skipZeros -o matrix.mat.gz
plotHeatmap -m matrix.mat.gz -out Heatmap1.png --whatToShow “plot, heatmap and colorbar”
```
<!--/TOC-->
