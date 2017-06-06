#!groovy

def imageName = 'jenkinsciinfra/confluence'

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    pipelineTriggers([[$class:"SCMTrigger", scmpoll_spec:"H/15 * * * *"]]),
])

node('docker') {
    def image
    stage('Build') {
        timestamps {
            deleteDir()
            checkout scm

            sh 'git rev-parse HEAD > GIT_COMMIT'
            shortCommit = readFile('GIT_COMMIT').take(6)
            def imageTag = "${env.BUILD_ID}-build${shortCommit}"
            echo "Creating the container ${imageName}:${imageTag}"
            image = docker.build("${imageName}:${imageTag}", '--no-cache --rm confluence')
        }

    }
    /* Assuming we're not inside of a pull request or multibranch pipeline */
    if (infra.isTrusted()) {
        stage('Publish') {
            timestamps { image.push() }
        }
    }
}
