###ECS

Responsible for provisioning ECS.  The services are two microservices written in Golang.

- [Range Micro 1](https://github.com/franknaw/range-micro-1)
- [Range Micro 2](https://github.com/franknaw/range-micro-2)

The ECS Task Definition uses the images digest hash so Terraform will automatically detect the new image during the apply process and spin up a new task.


