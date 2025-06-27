! Implement simple web-site with autoscaling and load-balancing

## Tasks:

1. Create 2 EC2-servers (t3.nano) with installed NGINX/apache or any other html/web service
2. Aplly most secure/strict policies in Security Group and NACL
3. No Public Key permitted. Organize access to EC2 shell via other fashion - again - use most secure way to get access available
4. Traffic should go through ALB - via special path '/main' route to EC2-1, via special header "X-target-web: second_ec2"
5. Put only Error and Critical logs to Cloudwatch for EC2-1
6. Keep all logs in EC2-2 locally - but apply archiving and come up with the way to send archives to newly created s3 bucket periodically.
7. S3 bucket must be private, encrypted by custom KMS, with CRR enabled to AIX DR region, with strict bucket policy allowing only necessary API operations/principals/etc.
8. Ensure that you can observe memory utilization in CW.
9. Ensure, that we can see somewhere in AWS all the installed patches, packets, versions and folder structure.
10. Ensure, that both EC2 instances going down at EOD in weekdays and holidays, and start up at SOD (clarify if needed)

## Project Structure
```
simple_web_site/
├── README.md
└── patches/
    └── v1/
        ├── Installed packets EC2-1      # Package list for ec2-nginx-dev-askar011-1
        ├── Installed packets EC2-2      # Package list for ec2-nginx-dev-askar011-2
        ├── configuration/
        │   ├── archive_logs.sh          # bash script that sends archives to s3
        │   └── user-data.sh             # User data script
        └── terraform/
            ├── main.tf                  # Main Terraform configuration
            ├── providers.tf             # Provider configurations
            └── variables.tf             # Variable definitions
            
```

## Architecture Overview
- **Primary Region**: eu-west-3 (Paris)
- **DR Region**: eu-central-1 (Frankfurt)
- **Availability Zones**: eu-west-3a, eu-west-3b
- **Instance Access**: AWS Systems Manager Session Manager


## Load Balancer Routing Rules
1. **Path-based routing**: `/main/*` → EC2-1 (tg-dev-askar011)
2. **Header-based routing**: `X-target-web: second_ec2` → EC2-2 (tg2-dev-askar011)
3. **Default routing**: All other traffic → EC2-1
4. **ALB DNS Name**: alb-dev-askar011-633812828.eu-west-3.elb.amazonaws.com


## Installed OS

Both EC2 instances running on
```
PRETTY_NAME="Ubuntu 24.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.2 LTS (Noble Numbat)"
```




## Services and Namings
```
ec2-1: ec2-nginx-dev-askar011-1
ec2-2: ec2-nginx-dev-askar011-2
sg: ec2-dev-askar011 (for ec2) 
sg: alb-dev-askar011 (for elb) 
role: test-ssm-askar  (for EC2 Instances) 
role: s3replicate_role_for_logs-ec2-dev-askar011    (for s3 cross region replication) 
source s3: logs-ec2-dev-askar011 (Paris) 
destination s3: logs-ec2-backup-dev-askar011 (Frankfurt) 
s3 replication: crr-dev-askar011 
kms: kms2-s3-dev-askar011 (Paris) 
kms: kms3-s3-dev-askar011 (Frankfurt) 
alb: alb-dev-askar011 
target group 1: tg-dev-askar011 
target group 2: tg2-dev-askar011 
loggroup-1: ec2-logs-error-dev-askar011-instanceID 
loggroup-2: ec2-logs-error-dev-askar011-instanceID 
```

## Tags
```
Owner:                askar 
User:                 askar011 
Environment:          dev 
Application:          nginx-web 
AWSService:           {aws service name} 
Name:                 {naming listed in 'Service and Namings'} 
```



QUESTIONS
### How you would implement HA and DR for web site?
 Multi-layered approach:
- **High Availability**: 
  - Multi-AZ deployment with ALB
  - Auto Scaling Group (min: 2, max: 4)
  - Health checks and automatic replacement
- **Disaster Recovery**: 
  - Hot Site in different region
  - Cross-region S3 replication backups and logs
  - Infrastructure as Code for rapid deployment

 
### What is the best way to backup and restore?
 Comprehensive backup strategy:
- **AWS Backup**: Centralized backup management
- **EBS Snapshots**: Daily automated snapshots
- **S3 Cross-Region Replication**: Log archives
- **Infrastructure**: Terraform state backup
- **Application**: Configuration files in version control
- **Retention**: 30 days for daily, 12 months for monthly backups