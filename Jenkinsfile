#!groovy

def imageName = 'jenkinsciinfra/confluence'

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    pipelineTriggers([[$class:"SCMTrigger", scmpoll_spec:"H/15 * * * *"]]),
])

node('docker') {
    checkout scm

    /* Using this hack right now to grab the appropriate abbreviated SHA1 of
     * our current build's commit. We must do this because right now I cannot
     * refer to `env.GIT_COMMIT` in Pipeline scripts
     */
    sh 'git rev-parse HEAD > GIT_COMMIT'
    shortCommit = readFile('GIT_COMMIT').take(6)
    def imageTag = "build${shortCommit}"


    stage 'Build'
    def whale = docker.build("${imageName}:${imageTag}", '--no-cache --rm confluence')

    stage 'Deploy'
    whale.push()
}
