### RANGE Deploy TF


```
$ ./provision.sh 
6 args are required
arg 1: provision environment (dev)
arg 2: terraform function (apply|plan|show|destroy)
arg 3: component sequence (ecr|rds|ecs|route53|all)
arg 4: project (RANGE|GUAC)
arg 5: region (com-west|com-east)
arg 6: Version

real	0m0.002s
user	0m0.002s
sys	0m0.000s

example:
$ ./provision.sh dev apply all RANGE com-east

When creating resource individually (not using "all"), 
both the creation and destroy component sequences matter.

Create Sequence:
"ecr" "rds" "ecs" "route53"

Destroy Sequence:
"route53" "ecs" "rds" "ecr"  

```

Deploy TF is made up from the following components.

- [ECR](ecr/README.md)
- [ECS](ecs/README.md)
- [RDS](rds/README.md)
- [Route53](route53/README.md)
- [Outputs](outputs/README.md)
- [Environment](environment/README.md)


***

