pipeline {
  agent { label 'Nikita_Alecsentsev' }

  parameters {
    string(name: 'TARGET_HOST', defaultValue: '192.168.199.71', description: 'Host IP')
    string(name: 'SSH_CRED_ID', defaultValue: 'nikita-ssh-final', description: 'SSH key')
  }

  stages {
    stage('Deploy') {
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: params.SSH_CRED_ID,
          keyFileVariable: 'SSH_KEY',
          usernameVariable: 'SSH_USER'
        )]) {
          sh '''
            scp -i $SSH_KEY docker-compose.yml ${SSH_USER}@${TARGET_HOST}:/tmp/
            ssh -i $SSH_KEY ${SSH_USER}@${TARGET_HOST} "cd /tmp && docker compose up -d"
          '''
        }
      }
    }
  }
}
