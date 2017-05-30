FROM openjdk:8u111-jdk-alpine

ARG JENKINS_VERSION=2.51
ARG JENKINS_SHA=5eca975de23a3bfb99b17b0185b0ea0be053448d
ARG MAVEN_VERSION=3.3.9
ARG DOCKER_VERSION=1.13.0
ARG DOCKER_SHA=fc194bb95640b1396283e5b23b5ff9d1b69a5e418b5b3d774f303a7642162ad6
ARG DOCKER_MACHINE_VERSION=0.8.2
ARG user=jenkins
ARG group=jenkins
ENV uid 1000
ENV gid 1000

RUN apk add --no-cache coreutils git openssh-client curl zip unzip bash ttf-dejavu ca-certificates openssl groff py-pip python jq

ENV JENKINS_HOME /var/jenkins_home

RUN mkdir -p /usr/share/jenkins/

# Install Jenkins
RUN curl -fsSL http://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war -o /usr/share/jenkins/jenkins.war \
  && echo "$JENKINS_SHA  /usr/share/jenkins/jenkins.war" | sha1sum -c -

# Install Maven
RUN cd /usr/local && \
    wget -O - http://mirrors.ibiblio.org/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xvzf - && \
    ln -sv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

# Install Docker (client)
RUN curl -fSL "https://get.docker.com/builds/$(uname -s)/$(uname -m)/docker-$DOCKER_VERSION.tgz" -o docker.tgz \
	&& echo "${DOCKER_SHA} *docker.tgz" | sha256sum -c - \
	&& tar -xzvf docker.tgz \
	&& mv docker/* /usr/local/bin/ \
	&& rmdir docker \
	&& rm docker.tgz \
	&& docker -v

# Install Docker Machine
RUN curl -fSL https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-$(uname -s)-$(uname -m) >/usr/local/bin/docker-machine \
    && chmod +x /usr/local/bin/docker-machine

# Install AWS CLI
RUN pip install awscli && apk --purge -v del py-pip

ENV PATH=/usr/local/maven/bin:$PATH
ENV DOCKER_HOST tcp://localhost:2376
ENV DOCKER_TLS_VERIFY 1
ENV DOCKER_CERT_PATH $JENKINS_HOME/.docker
ENV SSH_AUTH_SOCK /ssh_auth_sock

COPY files/ files/
COPY install-plugin.sh /usr/local/bin/
RUN chmod +x /files/init.sh /usr/local/bin/install-plugin.sh


RUN install-plugin.sh git 3.1.0
RUN install-plugin.sh pipeline-model-api 1.1.1
RUN install-plugin.sh pipeline-model-definition 1.1.1
RUN install-plugin.sh pipeline-rest-api 2.6
RUN install-plugin.sh pipeline-stage-view 2.6
RUN install-plugin.sh plain-credentials 1.4
RUN install-plugin.sh ssh-credentials 1.13
RUN install-plugin.sh workflow-job 2.10
RUN install-plugin.sh pipeline-milestone-step 1.3
RUN install-plugin.sh git-server 1.7
RUN install-plugin.sh github-api 1.85
RUN install-plugin.sh git-client 2.3.0
RUN install-plugin.sh github 1.26.1
RUN install-plugin.sh workflow-durable-task-step 2.10
RUN install-plugin.sh junit 1.20
RUN install-plugin.sh pipeline-graph-analysis 1.3
RUN install-plugin.sh pipeline-input-step 2.5
RUN install-plugin.sh ssh-slaves 1.15
RUN install-plugin.sh pipeline-stage-tags-metadata 1.1.1
RUN install-plugin.sh pipeline-model-extensions 1.1.1
RUN install-plugin.sh workflow-support 2.13
RUN install-plugin.sh pipeline-github-lib 1.0
RUN install-plugin.sh workflow-api 2.12
RUN install-plugin.sh docker-workflow 1.9.1
RUN install-plugin.sh pipeline-build-step 2.4
RUN install-plugin.sh scm-api 2.1.1
RUN install-plugin.sh pipeline-stage-step 2.2
RUN install-plugin.sh build-pipeline-plugin 1.5.6 
RUN install-plugin.sh maven-plugin 2.15.1 
RUN install-plugin.sh nexus-artifact-uploader 2.9 
RUN install-plugin.sh nexus-jenkins-plugin 1.2.20170428-142845.cb63c9e
RUN install-plugin.sh sonar 2.6.1 

EXPOSE 8080

ENTRYPOINT /files/init.sh && su jenkins -c "java -jar /usr/share/jenkins/jenkins.war --webroot=/tmp/jenkins/war --pluginroot=/tmp/jenkins/plugins"
