#!/bin/bash
set -euo pipefail

# Ask for the two variables up front
read -rp "Enter your NSID: " INPUT_1
read -rp "Enter your project folder name (ie. /project/bennett/<name>): " INPUT_2

# Stop if either value is empty or contains characters that would break the sed commands
for v in "$INPUT_1" "$INPUT_2"; do
    if [[ -z "$v" || "$v" =~ [^A-Za-z0-9._-] ]]; then
        echo "Error: '$v' is empty or has invalid characters (use letters, numbers, . _ -)" >&2
        exit 1
    fi
done

# Make directories
mkdir -p "$HOME"/{downloads,nextflow_configs,scripts,local,scratch,tmp}

# Copy database from project storage
cp -R /project/bennett/databases "$HOME"/databases

# Set up config and script files
cp "$HOME"/downloads/BennettAmpliseq/*.json "$HOME"/nextflow_configs/
cp "$HOME"/downloads/BennettAmpliseq/nextflow_job.sh "$HOME"/scripts/

# Replace 'NSID' with your NSID
sed -i "s/NSID/${INPUT_1}/g" "$HOME"/ampliseq/conf/plato.config
grep runOptions "$HOME"/ampliseq/conf/plato.config    # check it worked

# Change "-work-dir /project/bennett/work" to "-work-dir/project/bennett/<INPUT_2>/work"
sed -i "s|/project/bennett/work|/project/bennett/${INPUT_2}/work|g" "$HOME"/scripts/nextflow_job.sh
grep -- "-work-dir" "$HOME"/scripts/nextflow_job.sh    # check it worked
echo "Setup complete!"
