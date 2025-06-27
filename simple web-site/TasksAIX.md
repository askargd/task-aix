``` diff
! Implement simple web-site with autoscaling and load-balancing

Tasks:

1. Create 2 EC2-servers (t3.nano) with installed NGINX/apache or any other html/web service  +
  1.1 Нужно написать скрипт который установит nginx

2. Aplly most secure/strict policies in Security Group and NACL  +
  2.1 Разрешение только по 443 порту в SG и NACL

3. No Public Key permitted. Organize access to EC2 shell via other fashion - again - use most secure way to get access available  +
  3.1 Session Manager?

4. Traffic should go through ALB - via special path '/main' route to EC2-1, via special header "X-target-web: second_ec2"

5. Put only Error and Critical logs to Cloudwatch for EC2-1  +

6. Keep all logs in EC2-2 locally - but apply archiving and come up with the way to send archives to newly created s3 bucket periodically. 
  6.1 Написать скрипт и запустить крон джоб

7. S3 bucket must be private, encrypted by custom KMS, with CRR enabled to AIX DR region, with strict bucket policy allowing only necessary API operations/principals/etc.+

8. Ensure that you can observe memory utilization in CW.

9. Ensure, that we can see somewhere in AWS all the installed patches, packets, versions and folder structure.

10. Ensure, that both EC2 instances going down at EOD in weekdays and holidays, and start up at SOD (clarify if needed)



IMPORTANT
- Deadline is 23/06/2025.
- When you complete all the tasks, the requests from the office should display content from both of servers and its recommend to include EC2-instance internal IP address to the content.
- Every tasks "qosts" 10 points, so successfully implementing at least 7 task means you are good to go the next task set.


QUESTIONS
 - How you would implement HA and DR for web site?
 I would implement "Hot Site" in different AWS regions.
 - What is the best way to backup and restore?
 The best way to backup and restore is to use dedicated service AWS Backup. With AWS backup you can configure backup plan and make daily, weekly or monthly backups.







 Tags
 Owner: askar
 User: askar011
 Environment: dev
 Application: nginx-web
 AWSService

Naming

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

 arn:aws:s3:::SOURCE-S3-BUCKET                                arn:aws:s3:::logs-ec2-dev-askar011
 arn:aws:s3:::DESTINATION-S3-BUCKET                           arn:aws:s3:::logs-ec2-backup-dev-askar011
 source kms arn                                               arn:aws:kms:eu-west-3:176927891769:key/mrk-0cc282fd2abd4b178eed7e442599d963
 dest kms arn                                                 arn:aws:kms:eu-central-1:176927891769:key/mrk-0cc282fd2abd4b178eed7e442599d963