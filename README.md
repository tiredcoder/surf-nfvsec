# surf-nfvsec
Network Functions Virtualization and Security: Offering campus security by leveraging cloud-native infrastructure

This repo contains the K8S deployment (.yaml) and build (Dockerfile) files that were used to create the PoC.

Folders
 - controller: Contains the build and deploy scripts for the controller (Python web app using Flask).
 - database: Contains the build and deploy scripts for the database cluster (rqlite).
 - vnf: Contains the build and deploy scripts for the VNF (tcpdump).
 - results: Contains the network captures created by the VNF, and the steps that were taken to generate them.
 - doc: Contains documentation regarding how to install and configure the proof of concept.

The container images can also be found on Docker hub (latest builds only):
https://hub.docker.com/u/rjos3

Presentation:
https://homepages.staff.os3.nl/~delaat/rp/2018-2019/p11/presentation.pdf

Paper:
https://homepages.staff.os3.nl/~delaat/rp/2018-2019/p11/report.pdf

www.os3.nl
