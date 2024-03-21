# scoped_workshop

This repository creates two docker images,

- `spec` which contains the SPECFEM3D_GLOBE software
- `pypaw` which contains the pre/post processing software

To build the images, run the following command:

```bash
docker compose build
```

The code is compiled based on the contents in `DATA_in` directory.

Then a calculation can be run in the container by running the following command:

```bash
docker run --rm -it -v $(pwd)/sim_dir:/mnt/out scoped_workshop-spec bash
```

For putting out the result files from the container, it is necessary to copy the files into the mounted directory with `-v` option above.
For the example, the following command can be run in the container to copy the result files into the `sim_dir` directory.

```bash
cp -r /home/scoped/sim_dir/* /mnt/out
```

All the files in the `sim_dir` directory in the container are copied into the `sim_dir` directory in the host.

The information for the use of this image is available at https://containers-at-tacc.readthedocs.io/en/latest/singularity/03.mpi_and_gpus.html

For pushing the images to the docker hub, we at first need to login to the docker hub by running the following command:

```bash
docker login
```
then create a tag with username and push the image to the docker hub by running the following command:

```bash
docker tag scoped_workshop-spec:latest <username>/scoped_workshop-spec:latest
docker push <username>/scoped_workshop-spec:latest
```


To launch the jupyter server, run the following command:

```bash
docker compose up
```

Then jupyter notebook can be accessed at http://localhost:8888

