#!groovy
@Library('github.com/cloudogu/ces-build-lib@5.1.0')
import com.cloudogu.ces.cesbuildlib.*

git = new Git(this, "cesmarvin")
git.committerName = 'cesmarvin'
git.committerEmail = 'cesmarvin@cloudogu.com'
gitflow = new GitFlow(this, git)
github = new GitHub(this, git)
changelog = new Changelog(this)

repositoryName = "k8s-jenkins-agent-integration"
productionReleaseBranch = "main"

goVersion = "1.25"
helmTargetDir = "target/k8s"
helmChartDir = "${helmTargetDir}/helm"
registryNamespace = "k8s"
registryUrl = "registry.cloudogu.com"

node('docker') {
    timestamps {
        catchError {
            timeout(activity: false, time: 60, unit: 'MINUTES') {
                stage('Checkout') {
                    checkout scm
                    make 'clean'
                }

                new Docker(this)
                        .image("golang:${goVersion}")
                        .mountJenkinsUser()
                        .inside("--volume ${WORKSPACE}:/${repositoryName} -w /${repositoryName}")
                                {
                                    stage('Generate k8s Resources') {
                                        make 'helm-update-dependencies'
                                        make 'helm-generate'
                                        archiveArtifacts "${helmTargetDir}/**/*"
                                    }

                                    stage("Lint helm") {
                                        make 'helm-lint'
                                    }
                                }

                K3d k3d = new K3d(this, "${WORKSPACE}", "${WORKSPACE}/k3d", env.PATH)

                try {
                    stage('Set up k3d cluster') {
                        k3d.startK3d()
                    }

                    stage('Create jenkins service account') {
                        k3d.kubectl("create serviceaccount jenkins")
                    }

                    stage('Deploy Kyverno') {
                        k3d.helm("repo add kyverno https://kyverno.github.io/kyverno/")
                        k3d.helm("repo update")
                        k3d.helm("install kyverno kyverno/kyverno -n kyverno --create-namespace")
                    }

                    stage('Deploy Gatekeeper') {
                        k3d.helm("repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts")
                        k3d.helm("repo update")
                        k3d.helm("install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace")
                    }

                    stage('Deploy k8s-jenkins-agent-integration') {
                        k3d.helm("install ${repositoryName} ${helmChartDir} --set policies.gatekeeper.enabled=true")
                    }

                    stage('Test k8s-jenkins-agent-integration') {
                        k3d.kubectl("get ns jenkins-ci -o yaml")
                        k3d.kubectl("get clusterpolicy jenkins-ci-node-assign -o yaml")
                        k3d.kubectl("get assign jenkins-ci-node-affinity -o yaml")
                        k3d.kubectl("get assign jenkins-ci-node-tolerations -o yaml")
                        k3d.kubectl("get netpol agents-to-jenkins -o yaml")
                        k3d.kubectl("-n jenkins-ci get netpol jenkins-to-agents -o yaml")
                        k3d.kubectl("-n jenkins-ci get role jenkins-ci-role -o yaml")
                        k3d.kubectl("-n jenkins-ci get rolebinding jenkins-ci-binding -o yaml")
                    }
                } catch(Exception e) {
                    k3d.collectAndArchiveLogs()
                    throw e as java.lang.Throwable
                } finally {
                    stage('Remove k3d cluster') {
                        k3d.deleteK3d()
                    }
                }
            }
        }
    }

    stageAutomaticRelease()
}

void stageAutomaticRelease() {
    if (gitflow.isReleaseBranch()) {
        Makefile makefile = new Makefile(this)
        String releaseVersion = makefile.getVersion()
        String changelogVersion = git.getSimpleBranchName()

        stage('Push Helm chart to Harbor') {
            new Docker(this)
                    .image("golang:${goVersion}")
                    .mountJenkinsUser()
                    .inside("--volume ${WORKSPACE}:/${repositoryName} -w /${repositoryName}")
                            {
                                make 'helm-package'
                                archiveArtifacts "${helmTargetDir}/**/*"

                                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'harborhelmchartpush', usernameVariable: 'HARBOR_USERNAME', passwordVariable: 'HARBOR_PASSWORD']]) {
                                    sh ".bin/helm registry login ${registryUrl} --username '${HARBOR_USERNAME}' --password '${HARBOR_PASSWORD}'"
                                    sh ".bin/helm push ${helmChartDir}/${repositoryName}-${releaseVersion}.tgz oci://${registryUrl}/${registryNamespace}"
                                }
                            }
        }

        stage('Finish Release') {
            gitflow.finishRelease(releaseVersion, productionReleaseBranch)
        }

        stage('Add Github-Release') {
            releaseId = github.createReleaseWithChangelog(changelogVersion, changelog, productionReleaseBranch)
        }
    }
}

void make(String makeArgs) {
    sh "make ${makeArgs}"
}
