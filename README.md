# BennettAmpliseq

Bennett Lab amplicon analysis on the Plato HPC cluster.

The pipeline is [nf-core/ampliseq v2.17.0](https://nf-co.re/ampliseq/2.17.0/), versioned for the Genome Canada GG4GHG project.

---

## Contents

- [Primer information](#primer-information)
- [First-time setup](#first-time-setup)
- [Every run](#every-run)
- [During a run](#during-a-run)
- [After a run](#after-a-run)

---

## Primer information

| Target      | Gene fragment | Amplicon length (bp) | Config file          |
|-------------|---------------|----------------------|----------------------|
| Bacteria    | 16S           | 411                  | `nextflow_16S.json`  |
| Fungi       | ITS2          | 250–350+             | `nextflow_ITS2.json` |
| AMF         | 18S / SSU     | 530                  | `nextflow_AMF.json`  |
| Oomycetes   | ITS1          | 295                  | `nextflow_oomy.json` |
| Eukaryotes  | COI           | 313                  | `nextflow_insect.json` |

---

## First-time setup

### Programs you will need (on your own computer)

- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/): read quality checks
- [FileZilla](https://filezilla-project.org/): moves files between your computer and the HPC over SFTP
- [PuTTY](https://putty.org/index.html): SSH client (**Windows only**; macOS/Linux can use `ssh` in the terminal)

### 1. Clone this repository into `$HOME/downloads`

```bash
mkdir -p $HOME/downloads
git clone https://github.com/roylejw/BennettAmpliseq.git $HOME/downloads/BennettAmpliseq
```

### 2. Unzip the pipeline into `$HOME/ampliseq`

```bash
unzip -q $HOME/downloads/BennettAmpliseq/ampliseq.zip -x '__MACOSX/*' -d $HOME
ls $HOME/ampliseq    # should list main.nf, nextflow.config, conf/, ...
```

### 3. Copy the reference databases

```bash
cp -R /project/bennett/databases $HOME/databases
```

### 4. Copy the config templates into `$HOME/nextflow_configs`

```bash
mkdir -p $HOME/nextflow_configs
cp $HOME/downloads/BennettAmpliseq/*.json $HOME/nextflow_configs/
```

### 5. Copy the job script into `$HOME/scripts`

```bash
mkdir -p $HOME/scripts
cp $HOME/downloads/BennettAmpliseq/nextflow_job.sh $HOME/scripts/
```

### 6. Set your NSID in the cluster config

The Singularity bind mounts in `plato.config` need your NSID. It appears several times, so replace every copy at once (swap `abc123` for your NSID):

```bash
sed -i 's/NSID/abc123/g' $HOME/ampliseq/conf/plato.config
grep runOptions $HOME/ampliseq/conf/plato.config    # check it worked
```

Or edit it by hand with `nano $HOME/ampliseq/conf/plato.config` and change every `NSID` in the `singularity` section.

### 7. Set your own work directory in the job script

The job script needs a working directory for temporary files. Point it at your own folder in project storage:

```bash
nano $HOME/scripts/nextflow_job.sh
```

```bash
	-work-dir /project/bennett/<your_folder>/work \
```

To save and exist nano, press ctrl + x, then press y to save your work, and then enter to overwrite the existing file. If you don't wish to save, press ctrl + x, then n instead to exit without saving.

---

## Every run

1. **Move the sequences from Datastore into your project storage folder.**
   Globus is the recommended way to do this.

2. **Check read quality with [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).**
   The pipeline runs with `--skip_fastqc`, so you have to do this step yourself. You will use the results in step 5.

3. **Create a samplesheet and upload it to your HPC home directory.**
   It is a tab-separated file with this header (see [`example_samplesheet.tsv`](example_samplesheet.tsv)):

   ```tsv
   sampleID	forwardReads	reverseReads
   sample_A	/project/bennett/<you>/sequences/<run>/<sample>_R1.fastq.gz	/project/bennett/<you>/sequences/<run>/<sample>_R2.fastq.gz
   ```

   Sample names must follow these rules:
   - No duplicate names
   - The first character must be a letter
   - Only letters (`a–z`, `A–Z`), numbers (`0–9`) and underscores (`_`). No hyphens, spaces or other special characters.

   Read paths must be **absolute** (full) paths.

4. **Copy the config file for your primer** (see [Primer information](#primer-information)) and open it in Notepad or a similar text editor.

5. **Set `trunclenf` and `trunclenr`** based on where the quality score drops off in FastQC and on how much the reads need to overlap. We sequence 2 × 300 bp on a NextSeq 2000.
   - The forward and reverse reads must still overlap after truncation: `trunclenf + trunclenr` should be at least the amplicon length plus about 20 bp.
   - **16S:** skip this step. Truncation lengths are computed automatically from `trunc_qmin`.
   - The templates ship with these fields **empty** (`"trunclenf": ,`). That is not valid JSON, and the run will fail until you enter numbers.

   ```json
   "trunclenf": 240,
   "trunclenr": 200,
   ```

6. **Set `input` and `outdir`.**
   - `input`: the full path to your samplesheet
   - `outdir`: your output folder in project storage

   Use full paths, not `~` or `$HOME` (run `echo $HOME` on the HPC to get the full path). **AMF only:** also set `kraken2_ref_tax_custom` to the full path of `databases/amf_maarjam_vtx_db` in your home directory.

   ```json
   "input": "/home/abc123/samplesheet.tsv",
   "outdir": "/project/bennett/<you>/out_redberry16S",
   "kraken2_ref_tax_custom": "/home/abc123/databases/amf_maarjam_vtx_db"
   ```

7. **Save the config under a name that identifies the run**, in the format `nextflow_<ID>.json`.
   Example: `nextflow_redberry16S.json`

8. **Upload the config to `$HOME/nextflow_configs`.**

9. **Put the run ID in the job script's `primer=""` line.**

   ```bash
   nano $HOME/scripts/nextflow_job.sh
   ```

   ```bash
   primer="redberry16S"    # loads $HOME/nextflow_configs/nextflow_redberry16S.json
   ```

10. **Submit the job.**

    ```bash
    sbatch $HOME/scripts/nextflow_job.sh
    ```

---

## During a run

### Monitor the queue with `squeue`

```bash
# All queued jobs, from everyone
squeue

# Only your jobs ($USER is your NSID)
squeue -u $USER

# Watch your jobs live, updating every 2 seconds (Ctrl+C to exit)
watch -n 2 squeue -u $USER
```

### Follow the job log

Each submitted job writes a `slurm-<jobID>.out` file in the directory you ran `sbatch` from. Use it to troubleshoot errors or to see what the pipeline is currently doing. Replace `12345` with your job ID from `squeue`:

```bash
tail -f slurm-12345.out    # Ctrl+C to stop following
```

To cancel a job:

```bash
scancel 12345
```

---

## After a run

- [ ] Open the HTML run summary in `outdir/summary_report/`
- [ ] Inspect the taxonomy and ASV tables
  - Are there more or fewer ASVs than you expected?
  - Did you hit the organisms you targeted?
- [ ] Move the output to permanent storage (Datastore)
- [ ] **Delete your sequences from `/project`**
- [ ] **Delete your Nextflow work directory** (the `-work-dir` set in the job script):

  ```bash
  rm -rf /project/bennett/<your_folder>/work
  ```

> [!WARNING]
> Only delete a work directory when **no one is running an analysis from it**. Deleting a work directory during a run will crash that run. Check first with `squeue -u $USER` (and ask the lab if the directory is shared).
