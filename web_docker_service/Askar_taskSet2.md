``` diff
# Task set 2

1. Create local repository called "web_docker_service"
    - Move this file as README file to the newly created repository.
    - push local repository to AIX GITLAB CI/CD platform

2. Deploy web server in AWS ECS:
    - create some database in docker - populate with some data and show in the frontend page
        - nice to have: db autentication, url , usernames, all  should be implemented via aws parameter store
    - Public IP assignment must be disabled
    - Security groups should permit only AIX Office network
    - ECS service name should be the same as repository name
    - Use Dockerfile to build your container
    - Pipeline must include 4-step deployment: build image, test, publish image to aws, apply image in aws.
    - No manual deployment - use Terraform to provision and manage infrastructure.
    - apply scaling up for containers when cpu >=85% to double replica and scale down when riches stable state.
    - apply automatic mechanism/approach to shutdown service on weekdays - keep run only till 12 PM since morning and keep shutdown during weekend (bash scripting is not allowed)
    - deploy alarming to your email address when you see some errors in logs when  you app is running
    - a pipeline should trigger for full cycle when you are merge changes or push into 'dev' branch, but run only build and test when you send 'merge_request' hook
    - all your services should be landed into the same AZ - where you have NatGW provisioned
    - all resources should have proper tags and name - avoid putting your name to the resource's name, instead - think about how the organizations would developed naming for their infrastructure
    - VPC, NATGW, IGW and other Core components should be imported via 'data' command - not need to create new resources.
    - think about load-balancing - all the traffic to web service should be load-balanced - specifically when scaling on the scene
    - try to use vars as much as possible - try to avoid hardcoding values
    - Create gitlab-ci.yml pipeline file to build, test and deploy to new ecs cluster

!NOTE:
! You need to demonstrate work with git protocol and Gitlab CI/CD,
! and explain all steps that your pipeline does
! Your should keep a docker image in AWS ECR as a container registry and all images have to be differenciated with git hash tag
! You are welcome to use any publicly available resources to get done this task, but bear in mind that you have to follow "clear code" approach and be able to explain every string in your pipeline code.
! Deadline is  15th of July, 2025.

