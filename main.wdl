version 1.0
import "modules/quantifyReads.wdl" as Count
import "modules/dataStructures.wdl" 

workflow scATACseq {
	input {
		# base
		String dockerBase
		String uuid
		String species
        String genomeVersion
=		Array[DesignMatrix] designMatrices

		# cellRanger
		Int cellRangerMemory = 64
        Int cellRangerNumberCpuThreads = 8
        Int cellRangerNumberMaxRetries = 1
	}

	String dockerPrefix = species + genomeVersion
    String dockerUri = dockerBase + dockerPrefix

    scatter(designMat in designMatrices) {
    call Count.cellRangerAtacCount as Count {
			input: 
                fastqs = flatten(designMat.fastqs),
                sampleName = designMat.sampleName,
                sampleType = designMat.sampleType,
				dockerUri = dockerUri,
                dockerMemoryGB = cellRangerMemory,
                numberCpuThreads = cellRangerNumberCpuThreads,
                numberMaxRetries = cellRangerNumberMaxRetries
		}
    }

	# Retrieve metadata info over designMatrices
	scatter(designMat in designMatrices){
		String sampleName = designMat.sampleName
		String sampleType = designMat.sampleType
        String batch = designMat.cols.batch
	}

	Array[String] samplesName = sampleName
	Array[String] samplesType = sampleType
    Array[String] batches = batch

    call Count.cellRangerAtacAggr as Aggr {
			input:
				sampleName=samplesName,
		        sampleType=samplesType,
                batch=batches,
                fragments = Count.fragments,
				fragments_tbi = Count.fragments_tbi,
                singleCellCsv = Count.singleCellCsv,
                dockerUri = dockerUri,
                dockerMemoryGB =cellRangerMemory,
                numberCpuThreads = cellRangerNumberCpuThreads,
                numberMaxRetries = cellRangerNumberMaxRetries
	}

	output {
        Array[File] cellRangerAtacResults = Count.cellRangerAtacResults
        File cellRangerAtacAggrResults = Aggr.cellRangerAggResults
	}

	meta {
		description: "scATAC-seq workflow with the cellRanger-atac pipeline."
		author: "Kane Toh"
		email: "kanetoh@nus.edu.sg"
	}
}