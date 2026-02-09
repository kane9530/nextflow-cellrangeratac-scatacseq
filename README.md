# Description

As a bioinformatician with the [Genomics and Data Analytics Core](https://csi.nus.edu.sg/our-research/core-facilities/genomics-and-data-analytics-core-gedac/), we were responsible for building a cloud-platform for users to run their bioinformatics workflow. We elected to use Nextflow for many of our analyses tasks. 

Here, I wrote a Nextflow DSL-2 implementation of the cellranger-atac (v2.1.0) pipeline for single-cell ATAC-seq analysis.
This is a prototype that will be deployed on AWS via the Amazon Genomics CLI (AGC), as part of the suite of
scalable omics analysis pipelines offered by the Genomics and Data Analytics Core (GeDaC) core facility in
the Singapore Cancer Science Institute (CSI). 

The simple pipeline first runs `fastp` on all the R1 and R3 fastq reads as quality control, and then collates
all the `*fastp.json` files into a single report with `multiQC`. This is followed by an implementation of the
`cellranger-atac count` step to identify the ATAC peaks.


