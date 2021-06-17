/*
 * Jenkinsfile for building bookkeeper for ECS Flex
 */

import groovy.json.JsonOutput


PIPELINES_BRANCH_NAME = 'master'
STORAGE_DEVKIT_IMAGE = 'asdrepo.isus.emc.com:8085/emcecs/devkit:3.7.0.0.2.java11_default'
STORAGE_DEVKIT_ARGS = '--net="host" --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /root:/root -v /var/tmp:/var/tmp -v /tmp:/tmp -v /home:/home -v /var/gradle:/var/gradle -v "/var/.m2:/root/.m2"'

loader.loadFrom(['pipelines': [common          : 'common',
                               custom_packaging: 'packaging/custom_packaging'],
                 'branch'   : PIPELINES_BRANCH_NAME])

this.build()

void build() {
    Map<String, Object> args = [
        // object service
        serviceBranchName: params.BRANCH,
        serviceDirectory : 'docker/bookkeeper',
        componentName    : 'bookkeeper',
        clientDirectory  : 'bookkeeper',
        version          : '',
        commit           : '',
        pushToArtifactory: params.PUSH_TO_HARBOR,
        serviceImageName : 'bookkeeper',
        imageTag         : params.HARBOR_TAG,
        publishRepoName  : common.ARTIFACTORY.ECS_BUILD_REPO_NAME,
        // slack
        slackChannel     : common.SLACK_CHANNEL.ECS_FLEX_CI,
    ]

    def scmData
    try {
        common.node(label: common.JENKINS_LABELS.FLEX_CI, time: 30) {
            /*
             * IMPORTANT: all sh() commands must be performed from withDockerContainer() block
             */
            common.withInfraDevkitContainer() {
                stage('Git Clone') {
                    scmData = checkout([
                          $class: 'GitSCM',
                          branches: scm.branches,
                          doGenerateSubmoduleConfigurations: false,
                          userRemoteConfigs: scm.userRemoteConfigs
                    ])
                    args.commit = scmData.GIT_COMMIT
                }

                stage('Fingerprinting') {
                    // get the version from variables.mk
                    args.version = common.getMakefileVar('FULL_VERSION', "${args.serviceDirectory}/variables.mk")
                    // fingerprints for downstream builds

                    custom_packaging.fingerprintVersionFile('bookkeeper', args.version)
                }

                stage('Build Image') {
                    sh("cd ${args.serviceDirectory}; docker build .")
                }

                stage('Push Image') {
                    if (args.pushToArtifactory == true) {
                        String tag = (args.imageTag) ?: args.version
                        String imageRepo = common.getMakefileVar('BOOKKEEPER_REPO_REPO', "${args.serviceDirectory}/variables.mk")
                        String pushPath = "${common.DOCKER_REGISTRY.ASDREPO_OBJECTSCALE_REGISTRY.getRegistryUrl()}/${args.serviceImageName}"

                        sh("""
                            docker tag $imageRepo:${args.version} $pushPath:$tag
                            docker push $pushPath:$tag
                        """)
                    } else {
                        println('... Skip pushing image')
                    }
                }

                stage('Build Client') {
                    sh("cd ${args.clientDirectory}; ../gradlew :${args.clientDirectory}:build")
                }

                stage('Publish Client') {
                    if (args.pushToArtifactory == true) {
                        String publishUrl = common.ARTIFACTORY.getUrlForRepo(args.publishRepoName)
                        String publishCred = common.ARTIFACTORY.getCredentialsIdForPublish(args.publishRepoName)
                        timeout(60) {
                            withCredentials([[$class          : 'UsernamePasswordMultiBinding',
                                              credentialsId   : publishCred,
                                              usernameVariable: 'USERNAME',
                                              passwordVariable: 'PASSWORD',],]) {
                                sh("./gradlew -PpublishUrl=${publishUrl} -PpublishUsername=${env.USERNAME} -PpublishPassword=${env.PASSWORD} publish")
                            }
                        }
                    }
                }

                // create bookkeeper release manifest in
                stage('Publish manifest') {
                    this.createComponentManifest(
                            componentVersion: args.version,
                            componentName: args.componentName,
                            componentImage: args.serviceImageName,
                            commit: args.commit
                    ) 

                    common.publishManifest(
                            product: 'objectscale',
                            componentName: args.componentName,
                            componentVersion: args.version,
                    )
                }

            }
        }
    }
    catch (any) {
        println any
        common.setBuildFailure()
        throw any
    }
    finally {
        currentBuild.description = common.getObjectServiceBuildDescription(args)
        //common.slackSend(channel: args.slackChannel, sendOnFailureOnly: true)
        reportBuildResult(script: this, topic: DRPKafkaTopic, scmData: scmData) // publish metrics to DRP
    }
}

String createComponentManifest(Map<String, String> manifestVars) {
    String manifestContent = JsonOutput.prettyPrint("""
        {
            "manifestFormatVersion": "2",
            "componentName": "${manifestVars.componentName}",
            "componentVersion": "${manifestVars.componentVersion}",
            "buildRepos": [
                {
                    "url": "https://github.com/realAaronWu/pravega.git",
                    "commit": "${manifestVars.commit}"
                }
            ],
            "componentArtifacts": [
                {
                    "artifactId": "bookkeeper-docker-image",
                    "version": "${manifestVars.componentVersion}",
                    "type": "docker-image",
                    "endpoint": "{{ OBJECTSCALE_REGISTRY }}",
                    "path": "${manifestVars.componentImage}"
                }
            ]
        }
    """)

    writeFile(file: 'artifacts.json', text: manifestContent)
}


this
