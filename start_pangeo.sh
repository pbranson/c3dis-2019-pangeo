#!/bin/bash -l

#SBATCH --partition=workq
##SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=24:00:00
#SBATCH --account=pawsey0106
#SBATCH --export=NONE
#SBATCH -J pangeo    # name
#SBATCH -o pangeo-%J.out

module unload numpy
module unload python

export PATH=/group/pawsey0106/miniconda3/bin:$PATH
source activate pyAODN

# Create trap to kill notebook when user is done
kill_server() {
    if [[ $JNPID != -1 ]]; then
        echo -en "\nKilling Jupyter Notebook Server with PID=$JNPID ... "
        kill $JNPID
        echo "done"
        exit 0
    else
        exit 1
    fi
}

let DASK_PORT=8787
let LOCALHOST_PORT=8888

JNHOST=$(hostname)
JNIP=$(hostname -i)

LOGFILE=$MYSCRATCH/pangeo_jupyter_log.$(date +%Y%m%dT%H%M%S)


echo "Logging jupyter notebook session on $JNHOST to $LOGFILE"
export XDG_RUNTIME_DIR=""
srun -n 1 -c $SLURM_CPUS_PER_TASK --export=ALL jupyter notebook $@ --no-browser --ip=$JNHOST >& $LOGFILE &
JNPID=$!

echo -en "\nStarting jupyter notebook server, please wait ... "

ELAPSED=0
ADDRESS=

while [[ $ADDRESS != *"${JNHOST}"* ]]; do
    sleep 1
    ELAPSED=$(($ELAPSED+1))
    ADDRESS=$(grep -e '^\[.*\]\s*http://.*:.*/\?token=.*' $LOGFILE | head -n 1 | awk -F'//' '{print $NF}')

    if [[ $ELAPSED -gt 60 ]]; then
        echo -e "something went wrong\n---"
        cat $LOGFILE
        echo "---"
        kill_server
    fi
done

echo -e "done\n---\n"

HOST=$(echo $ADDRESS | awk -F':' ' { print $1 } ')
PORT=$(echo $ADDRESS | awk -F':' ' { print $2 } ' | awk -F'/' ' { print $1 } ')
TOKEN=$(echo $ADDRESS | awk -F'=' ' { print $NF } ')

cat << EOF
Run the following command on your desktop or laptop:
    ssh -N -l $USER -L ${LOCALHOST_PORT}:${JNHOST}:$PORT zeus.pawsey.org.au
Log in with your Username/Password or SSH keys.
Then open a browser and go to http://localhost:${LOCALHOST_PORT}. The Jupyter web
interface will ask you for a token. Use the following:
    $TOKEN
Note that anyone to whom you give the token can access (and modify/delete)
files in your PAWSEY spaces, regardless of the file permissions you
have set. SHARE TOKENS RARELY AND WISELY!
To stop the server, press Ctrl-C.
EOF

# Wait for user kill command
sleep inf

