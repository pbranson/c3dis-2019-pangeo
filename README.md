# c3dis-2019-pangeo

A set of notebooks demonstrating recent functionality provided by the libraries promulgated through [Pangeo community](http://pangeo.io)

To setup and use these notebooks from HPC (at Pawsey/CSIRO) there are some helper scripts and config files. 

More details guide available here:	 http://pangeo.io/setup_guides/hpc.html

### TL;DR version:
```
git clone https://github.com/pbranson/c3dis-2019-pangeo.git
cd c3dis-2019-pangeo
conda env create –f environment.yaml
conda activate pyAODN
cp jobqueue.yaml ~/.config/dask/
sbatch start_pangeo.sh
ssh -N -l pbranson -L 8888:z043:8888 zeus.pawsey.org.au
```
The correct format for the last line will be printed to the job output file pangeo-######.out, along with the security token to login to the jupyter server.
