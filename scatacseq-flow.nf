include { 
  QC_FASTP               ;
  QC_MULTIQC             ;
  CELLRANGER_ATAC_COUNT  ;
 } from './modules/scatacseq-tasks.nf'  

workflow scATACseqFlow {
    // required inputs
    take:
      info_ch
      grouped_ch 
      reference_ch
    // workflow implementation
    main:
        QC_FASTP(info_ch)
        QC_MULTIQC(QC_FASTP.out.fastp_json.collect())
        CELLRANGER_ATAC_COUNT(grouped_ch, reference_ch)
}