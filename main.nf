include { scATACseqFlow } from './scatacseq-flow.nf'

/* 
    The design csv file must have the following 6 column headers:
    sample_name <val> : sample name e.g. pbmc_1k
    sample_type <val> : sample type e.g. tumor|normal
    fastq_R1 <path>: S3 path to read1
    fastq_R2 <path>: S3 path to dual index i5 read 
    fastq_R3 <path>: S3 path to read2
    lane <string>: flow cell lane
*/   
params.designCsv = "${baseDir}/design.csv"
params.reference = "s3://gedac-bucket-dev/workflows/agc/scatacseq/ref/grch38/"

log.info """\n
         s c A T A C - S E Q  P I P E L I N E    
         ====================================
         design file  : ${params.designCsv}
         reference    : ${params.reference}
         outdir       : ${params.outdir}
         """
         .stripIndent()

workflow {

    info_ch = Channel.fromPath(params.designCsv) \
        | splitCsv(header:true) \
        | map { row ->  
          tuple row.sample_name, row.sample_type, row.lane, 
          file(row.fastq_R1), file(row.fastq_R2), file(row.fastq_R3)
        }

    grouped_ch = info_ch 
        | map { it ->
        def meta = ["sample_name":it[0], 
                    "sample_type":it[1]]
        def reads = [it[3], 
                    it[4], 
                    it[5]]
        return tuple(meta, reads)
        }
        | groupTuple(by:0)
        | map { it ->
            tuple it[0], it[1].flatten()
        }
    reference_ch = Channel.value(params.reference)

    scATACseqFlow(info_ch, grouped_ch, reference_ch)
}

workflow.onComplete{
    log.info (workflow.success ? "\nscATAC-seq workflow complete!" : "Oops.. something went wrong!")
}

