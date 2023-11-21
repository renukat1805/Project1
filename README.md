# Build CI / CD Pipeline using Jenkins and deploy the real world Web Application in AWS Cloud

Technologies Used:-
-------------------
1. Jenkins
2. Groovy
3. AWS Cloud
4. Git
5. Docker  

Pre-Requiset:
--------------
* Setup Jenkins (ubuntu with t2.large)
* setup webhook integration for automatic Build Triggers 
* Create A Role (name: project_ecr_role) with AmazonEC2ContainerRegistryFullAccess attach to Jenkins Machine  
* Create ECR Repository in the same region where jenkins machine available For to upload image into that repository 

jenkinsFile Code steps
-------------------------------
>step1: To build pipeline code,we need to create agent machine and include here to build job from agent machine 
   
    pipeline
    {
        agent any
    }

>step2: To Pass environments in jenkins

    environment {
        APP_NAME = "tomcat"
        ECR_REGISTRY = "172701893228.dkr.ecr.us-west-2.amazonaws.com"
        ECR_REPOSITORY = "renurepo"
        IMAGE_NAME = "${APP_NAME}"
        BUILD_VERSION = getVersion()
    }

>step3: Download the code From Repository

        stage("Download the code")
        {
            steps
            {
                git 'https://github.com/renukat1805/Project1.git'
            }
        }

>step4: Build and test application code using maven 

        stage("Test the Application")
        {
            steps
            {
                    sh 'mvn test'
            }
        }
        stage("Build the Application")
        {
            steps
            {
                sh 'mvn package'
            }
        }

>step5: Build the Docker image 
    
* First Download Docker in Jenkins Machine for Building image from Dockerfile
       
        # sudo curl -fsSL https://get.docker.com -o install-docker.sh
        # sudo sh install-docker.sh

* Add jenkins user in dokcer group to build docker images directly 
        # sudo usermod -aG docker jenkins
* Add jenkins user in sudo group to run root commands. Also, enter details of jenkins user in sudoers file to avoid for asking password [ jenkins ALL (ALL:ALL) NOPASSWD:ALL ]
       
        # sudo usermod -aG sudo jenkins
        # vim /etc/sudoers
        
* To Build Docker image    
        
        stage("Building of Docker image")
        {
            steps
            {
                 sh "docker build -t $APP_NAME:$BUILD_VERSION ."
            }
        }

>step6: To push Docker image into ECR repository 
* if Jenkins machine is avilable in AWS cloud Environment that machine need to Contain a Role with  AmazonEC2ContainerRegistoryFullAccess and attach to jenkins machine
* If Jenkins machine available In local environment then that machine Required a User (navathej) with AdministrationAccess  
* check if ECR repository is available, if its not available then create the repository in AWS ECR service
* There are combination of steps included below to push already existing docker image into ECR repository 
* Below is the jenkins code to upload image into ECR repository 

        stage("Push the Docker image to ECR")
        {
            steps
            {
                script
                {
                    sh "aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker tag $APP_NAME:$BUILD_VERSION $ECR_REGISTRY/$ECR_REPOSITORY:$BUILD_VERSION"
                    sh "docker push $ECR_REGISTRY/$ECR_REPOSITORY:$BUILD_VERSION"
                }
            }
        }


>step7: Now delete the images on jenkins machine 
        
        stage("delete the Docker images on locally") 
        {
            steps
            {
                sh 'docker system prune -af'
            }
        }


>step8: Now pull ECR image into local machine for this we need to login to ECR and deploy it into EC2 Machine(Docker) 

* setup Docker machine (specify security group in the inbound rules. Open ssh 22 port to  admin access only and specify customised port 9898 to anyone to access our webpage)
* Establish Password Less Authentication from Jenkins machine to Docker machine 
* Add ubuntu user in docker group for to run docker commands 
* For this to create a role(name: project_ecr_role1) with AmazonEC2ContainerRegistryFullAccess attached to ec2-instance  

* Authenticate to AWS ECR for this machine we need to install AWSCLI and AWS Configure to create Accesskey and secretaccesskey on IAM for ECR permissions 

        # aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REGISTRY}

* pull image from ECR    

        # docker pull $ECR_REGISTRY/$ECR_REPOSITORY:$BUILD_VERSION
  
>step10: delete previous containers if running with same name (mytomee)

        stage("delete previous containers") 
        {
            steps
            {
               sh 'ssh ubuntu@172.31.18.30 docker rm -f mytomee'
            }
            
        }          

>step11: Now Run the container 

        stage("Run the Docker image")
        {
            steps
            {
                sh "ssh ubuntu@172.31.18.30 docker run --name mytomee -d -p 9898:8080 $ECR_REGISTRY/$ECR_REPOSITORY:$BUILD_VERSION"
            }
        }
>step12: stop previous containers if running with same name (mytomee)

        stage("stop previous containers") 
        {
            steps
            {
               sh 'ssh ubuntu@172.31.18.30 docker rm -f mytomee'
            }
            
        }        

>step13: setup to send Notification To gmail ( for this we need to setup smtp port in jenkins to particular gmail )

* according below steps if all steps gets success it will send project success message or if any step gets fail it will failed project
* To setup mail configuration in jenkins follow this link: https://drive.google.com/file/d/1G2HGfoGKyv3pzB1eLnW8mVxaUeltqpZ1/view?usp=drive_link
 

        post
        {
            success
            {
               mail bcc: '', body: 'CI/CD gets success', cc: '', from: '', replyTo: '', subject: 'Project completed successfully', to: 'renurenuka1807@gmail.com'
            }
            failure
            {
                mail bcc: '', body: 'CI/CD failed', cc: '', from: '', replyTo: '', subject: 'Project failed', to: 'renurenuka1807@gmail.com'
            }
        }


>step14: specify function to trigger build versions images 

        def getVersion() {
            def buildNumber = env.BUILD_NUMBER ?: '0'
            return "1.0.${buildNumber}"
        }

# All stages 

![Alt text](<Screenshot 2023-11-17 120406.png>)

# Gmail Notification 

![Alt text](email.png)
