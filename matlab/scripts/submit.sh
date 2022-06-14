#!/bin/bash
#SBATCH --account=p31274  ## YOUR ACCOUNT pXXXX or bXXXX
#SBATCH --partition=normal  ### PARTITION (buyin, short, normal, etc)
#SBATCH -n 1 ## how many computers do you need
#SBATCH --ntasks-per-node=2 ## how many cpus or processors do you need on each computer
#SBATCH --time=5:00:00 ## how long does this need to run (remember different partitions have restrictions on this param)
#SBATCH --mem-per-cpu=20G ## how much RAM do you need per CPU (this effects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name=wavelet  ## When you run squeue -u NETID this is how you can identify the job
#SBATCH --output=/home/yyr4332/logs/%A.log  ## standard out and standard error goes to this file
#SBATCH --mail-type=ALL ## you can receive e-mail alerts from SLURM when your job begins and when your job finishes (completed, failed, etc)
#SBATCH --mail-user=yyu@u.northwestern.edu ## your email
###SBATCH --constraint="[quest5|quest6|quest8|quest9]" ### you want computers you have requested to be from either quest5 or quest6/7 or quest8 or quest 9 nodes, not a combination of nodes. Import for MPI, not usually import for job arrays)

module purge all
module load matlab/r2020b

cd /home/yyr4332/project/matlab/
matlab -nosplash -nodesktop -singleCompThread -r yy_auto_process
###matlab -nosplash -nodesktop -singleCompThread -r process_ICA
###matlab -nosplash -nodesktop -singleCompThread -r junk_runPCA


###sbatch --export=hmm_n=3,repeat=1,seed=0,iter=50 project/EEG-decode/submit.sh
###sbatch --export=hmm_n=3,repeat=1,seed=0,iter=50 project/matlab/scripts/submit.sh

