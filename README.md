# Task-Distributor - A Task Distributor for Clusters


Task-Distributor is a collection of two bash scripts, which simplify the 
parallel generation of images by using the ray tracing software POV-Ray by using 
multiple worker nodes in parallel. POV-Ray supports to calculate just a part of 
the final image (a limited number of rows). 

## Synopsis

task-distributor-master.sh -n nodes -x width -y height -p path

## Requirements

These software packages must be installed on all worker nodes:

- POV-Ray 3.7
- bash 4.2.37
- ImageMagick 6.7.7
- bc 1.06.95

A shared folder, which can be accessed by the master node and all 
worker nodes must exist, because this shared folder is required to store the 
lockfile and the image parts. The shared folder can be implemented via a 
distributed file system or a protocol (e.g. NFS) 

## Components 

The two shell scripts are in detail:

### task-distributor-master.sh

This script creates a lockfile on a shared folder, which can be accessed by the 
master node and all worker nodes.

As next step, the script starts via ssh a POV-Ray job on each worker node. 

After the POV-Ray jobs have been started, the script checks in an infinite loop 
if each worker node has placed its hostname into the lockfile. If this 
condition is met, the script composes the image parts via the command line tool 
convert from the ImageMagick project to create the final image.

### task-distributor-worker.sh

This script must be located on each worker node because it executes the POV-ray 
render job according to the instructions of the master node and stores the 
resulting image part on a shared folder, which can be accessed by the master 
node and all worker nodes.

It is possible with POV-Ray to render only a subset of **rows** but since POV-Ray 
3.7 the output is always a full height image and not rendered rows are filled 
with black pixels. 

The script removes the black rows with the command line tool convert from the 
ImageMagick project to reduce the network traffic and the amount of data which 
needs the master to process finally for creating the final image.

Finally, the script writes the hostname of the worker node into the lockfile to 
inform the master node that the image part of this worker node is now available.

## Workflow

![Task-Distributor 1/4](christianbaun.github.com/task-distributor/blob/master/wiki/images/Task_Distributor_Workflow_part1.png)

## Example

`./task-distributor-master.sh -n 8 -x 800 -y 600 -p /glusterfs/povray`

## Web Site

Visit the Task-Distributor for more information and the latest revision.

[https://github.com/christianbaun/task-distributor](https://github.com/christianbaun/task-distributor)

## License

GPLv2 or later.

[http://www.gnu.org/licenses/gpl-2.0.html](http://www.gnu.org/licenses/gpl-2.0.html)
