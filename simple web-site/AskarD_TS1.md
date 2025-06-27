``` diff
! Implement simple web-site with autoscaling and load-balancing

Tasks:

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



IMPORTANT
- Deadline is 23/06/2025.
- When you complete all the tasks, the requests from the office should display content from both of servers and its recommend to include EC2-instance internal IP address to the content.
- Every tasks "qosts" 10 points, so successfully implementing at least 7 task means you are good to go the next task set.


QUESTIONS
 - How you would implement HA and DR for web site?
 - What is the best way to backup and restore?