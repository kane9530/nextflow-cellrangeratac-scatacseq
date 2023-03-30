process QC_FASTP {

    label "mem_large"
    container '026171442599.dkr.ecr.ap-southeast-1.amazonaws.com/qc:latest'
    publishDir "${params.outdir}/fastp", mode:"copy", failOnError:true 

    input:
    tuple val(sample_name), val(sample_type), val(lane), 
          path(fastq_R1), path(fastq_R2), path(fastq_R3)
    
    output:
    path "*fastp.json", emit: fastp_json
    path "*fastp.html", emit: fastp_html
    path "*.fastp.fastq.gz", emit: fastp_fastq

    shell '/bin/bash', '-euo', 'pipefail'

    """
    fastp -i ${fastq_R1} \\
    -I ${fastq_R3} \\
    -o ${extract_10x_substring(fastq_R1)}.fastp.fastq.gz \\
    -O ${extract_10x_substring(fastq_R3)}.fastp.fastq.gz \\
    --detect_adapter_for_pe \\
    --thread $task.cpus \\
    --html ${sample_name}_${sample_type}_${lane}_fastp.html \\
    --json ${sample_name}_${sample_type}_${lane}_fastp.json
    """
}

process QC_MULTIQC {

    label "mem_small"
    container '026171442599.dkr.ecr.ap-southeast-1.amazonaws.com/qc:latest'
    publishDir "${params.outdir}/multiqc", mode:"copy", failOnError:true 

    input:
    path("*")

    output:
    path("multiqc_report.html")

    shell '/bin/bash', '-euo', 'pipefail'

    """
    multiqc .
    """
}

process CELLRANGER_ATAC_COUNT{
    
    tag  "${meta.sample_name}_${meta.sample_type}"
    label "retry_increasing_mem"
    container '026171442599.dkr.ecr.ap-southeast-1.amazonaws.com/cellranger_atac:latest'
    publishDir "${params.outdir}/cellranger-atac", mode:"copy", failOnError:true

    input:
    tuple val(meta), path(reads)
    path reference
    
    output:
    tuple val(meta), path("${meta.sample_name}_${meta.sample_type}/outs/*"), emit: outs
    

    script:
    """
    echo "meta sample name: ${meta.sample_name}\n"
    echo "meta sample type: ${meta.sample_type}\n"
    echo "reads: ${reads}\n"
    echo "ref : ${reference}\n" 

    cellranger-atac \\
        count \\
        --id='${meta.sample_name}_${meta.sample_type}' \\
        --fastqs=. \\
        --reference=${reference} \\
        --localcores=$task.cpus \\
        --localmem=${task.memory.toGiga()}
    """

    /*
    Interpreting results of 10x cellranger-atac
    https://cdn.10xgenomics.com/image/upload/v1660261285/support-documents/CG000202_TechnicalNote_InterpretingCellRangerATACWebSummaryFiles_RevB.pdf
    */
}


def extract_10x_substring(filename){
    //Hardcoded filename extraction as 10x filenames have a specific convention.
    //https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/fastq-input

    return filename.getName().split("_001")[0]
}