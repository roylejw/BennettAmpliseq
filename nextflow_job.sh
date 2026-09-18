#!/bin/bash
#SBATCH --job-name=head_job  # Job name
#SBATCH --time=120:00:00  # Max time limit
#SBATCH --nodes=1  # Number of nodes
#SBATCH --ntasks=1  # Number of tasks
#SBATCH --cpus-per-task=4  # Number of CPU cores per task
#SBATCH --mem=16G  # Memory allocation


primer=""

echo "Chosen primer is: "$primer""

cd $TMPDIR


# Nextflow setup
module purge 
module load python/3.11
module load rust         # New nf-core installations will error out if rust hasn't been loaded
module load postgresql   # Python modules which list psycopg2 as a dependency may crash without postgresql here.
python -m venv nf-core-env
source nf-core-env/bin/activate
python -m pip install nf_core==2.13
module load StdEnv/2023 nextflow/25.10.2 apptainer
export NXF_SINGULARITY_CACHEDIR=/project/bennett/NXF_SINGULARITY_CACHEDIR


#Run nextflow

nextflow run \
	"$HOME"/ampliseq/main.nf \
	-profile singularity \
	-c "$HOME"/ampliseq/conf/plato.config \
	-params-file "$HOME"/nextflow_configs/nextflow_"$primer".json \
	-work-dir /project/bennett/jack/work \
	--skip_tse \
	--skip_phyloseq \
	--skip_fastqc \
	--skip_multiqc
