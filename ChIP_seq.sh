#!/bin/sh

### created and update on 2020.10.01 by shuang as a ChIP seq pipeline
########################################################################################
#this is the step1, for alignment
########################################################################################

# Print start status message.
echo "job started"
start_time=`date +%s`

#ls -d */ |sed 's/\///' | uniq > filelist.txt
#ls | sed 's/_[12].fq.gz//' | uniq > filelist.txt
ls *.fq.gz | sed 's/_[12].fq.gz//' | uniq > filelist.txt

cat filelist.txt | while read line; do

	
input=`echo "$line" `

###   selecting different method(mkdir cd) in step with
#mkdir ${input}
# echo ${input} > stats.txt
# cd ${input}


##################################################################
#-S means generate sam format
##################################################################

bowtie2 -S $line.sam -p 16 -x /media/hp/disk1/song/Genomes/hg38/Sequences/WholeGenomeFasta/bowtie2/hg38 $line.fq.gz >> mapping_report.txt
 

##     if  runing line 28 , you should also run line 43 
#cd ${input}

samtools view -@ 16 -Sb $line.sam > $line.bam
samtools sort -@ 16 $line.bam -o $line.sort.bam

java -jar ~/picard/picard.jar MarkDuplicates I=$line.sort.bam O=$line.sort.markdup.bam M=$line.markdup.txt
samtools index $line.sort.markdup.bam
#samtools view -bq 1 $input\_sorted.bam > $input.unique.bam  #GET THE UNIQUE READS
# make bw files 
bamCoverage -p 16 -b ${line}.sort.markdup.bam -o ${line}.bw --binSize 10 --normalizeUsing RPGC --effectiveGenomeSize 2913022398 --extendReads 200
# cd ..
 
done


macs2 callpeak -t ${input}.bam -c ../wt_input/wt_input.bam -f BAM -g 4.1e8 -q 0.05 --broad --max-gap 500 -n $input 

computeMatrix scale-regions -S H3K9ac_EV.bw H3K9ac_FS.bw H3K9ac_FL.bw -R /media/hp/disk1/song/Genomes/${species}/Genes/genes.bed --beforeRegionStartLength 1000 --afterRegionStartLength 1000 --skipZeros -o matrix.mat.gz
plotHeatmap -m matrix.mat.gz -out Heatmap1.png --whatToShow “plot, heatmap and colorbar”






