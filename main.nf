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

// TODO: don't need but leaving as residue until I make an issue for remembering functionality
vcf_string =  vcf_for_create_GenomicsDB_V_string.map{'-V '+it.getName()+' ' }.toList().toString()


process create_GenomicsDB {

    tag "all_the_vcfs"
    publishDir "GenomicsDBImport_Results", mode: 'copy'
    container "broadinstitute/gatk:latest"

    input:
    file("*") from vcf_for_create_GenomicsDB_channel.collect()
    file("*") from vcf_tbi_for_create_GenomicsDB_channel.collect()
    file(ref) from ref_for_create_GenomicsDB_channel
    file(ref_index) from ref_index_for_create_GenomicsDB_channel
    file(ref_dict) from ref_dict_for_create_GenomicsDB_channel
    file(intervals) from intervals_create_GenomicsDB_channel
    val(vcf_string) from vcf_string

    output:
    file("*") into results_channel

    shell:
    '''
    echo -n "gatk GenomicsDBImport -R !{ref} --genomicsdb-workspace-path pon_db " > create_GenomicsDB.sh
    for vcf in $(ls *.vcf.gz); do
    echo -n "-V $vcf " >> create_GenomicsDB.sh
    done
    echo -n "-L !{intervals}" --merge-input-intervals --java-options '-DGATK_STACKTRACE_ON_USER_EXCEPTION=true' >> create_GenomicsDB.sh
    bash create_GenomicsDB.sh
    '''
}