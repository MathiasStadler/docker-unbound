# docker-unbound
- copy of https://github.com/MatthewVance/unbound-docker.git 

# Please visit for details  this project

# ENV
- HW Lenovo M92P
- LSB Version: ```lsb_release  -i -d -r -c```
    - Distributor ID: Ubuntu
    - Description:    Ubuntu 16.04.3 LTS
    - Release:        16.04
    - Codename:       xenial

- Fast internet

# Usage 
- git checkout
    - ```git clone https://github.com/MathiasStadler/docker-unbound.git```
- run unbound via docker
    - ```./run.sh```
- to force to build a new images
    - ```./run.sh -n```

# Used own A or PTR record 
    - Please edit the a-record.conf in the root directory of the project
    - The edit of the a-record.conf in the "current" directory  has no effect (Placeholder) 


