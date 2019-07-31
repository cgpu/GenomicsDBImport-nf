Channel
    .fromPath("${params.normal_vcf_folder}/*.vcf.gz")
    .into {  vcf_for_create_GenomicsDB_V_string ; vcf_for_create_GenomicsDB_channel }

Channel
    .fromPath("${params.normal_vcf_folder}/*.vcf.gz.tbi")
    .set {  vcf_tbi_for_create_GenomicsDB_channel }

Channel
    .fromPath(params.ref)
    .into { ref_mutect2_tum_only_mode_channel ; ref_for_create_GenomicsDB_channel ; ref_create_somatic_PoN }

Channel
    .fromPath(params.ref_index)
    .into { ref_index_mutect2_tum_only_mode_channel ; ref_index_for_create_GenomicsDB_channel ; ref_index_create_somatic_PoN }

Channel
    .fromPath(params.ref_dict)
    .into { ref_dict_mutect2_tum_only_mode_channel ; ref_dict_for_create_GenomicsDB_channel ; ref_dict_create_somatic_PoN }

Channel
    .fromPath(params.intervals_list)
    .set { intervals_create_GenomicsDB_channel  }

vcf_string =  vcf_for_create_GenomicsDB_V_string.map{'-V '+it.getName()+' ' }.toList().toString()


process create_GenomicsDB {

    tag "all_the_vcfs"
    publishDir "GenomicsDB_script_Results", mode: 'copy'
    container "broadinstitute/gatk:latest"

    input:
    file("*vcf.gz") from vcf_for_create_GenomicsDB_channel.collect()
    file("*vcf.gz.tbi") from vcf_tbi_for_create_GenomicsDB_channel.collect()
    file(ref) from ref_for_create_GenomicsDB_channel
    file(ref_index) from ref_index_for_create_GenomicsDB_channel
    file(ref_dict) from ref_dict_for_create_GenomicsDB_channel
    file(intervals) from intervals_create_GenomicsDB_channel
    val(vcf_string) from vcf_string

    output:
    file("create_GenomicsDB.sh") into results_channel

    shell:
    '''
    echo -n "gatk GenomicsDBImport -R !{ref}  --genomicsdb-workspace-path pon_db --java-options '-DGATK_STACKTRACE_ON_USER_EXCEPTION=true' !{vcf_string}" > create_GenomicsDB.sh
    echo -n "-L !{intervals}" >> create_GenomicsDB.sh
    cat create_GenomicsDB.sh
    '''
}
