pipeline {
  agent { label 'Nikita_Alecsentsev' }

  parameters {
    choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Terraform action')
  }

  stages {
    stage('Init') {
      steps {
        sh '''
          . /home/ubuntu/openrc.sh
          terraform init
        '''
      }
    }
    
    stage('Apply/Destroy') {
      steps {
        sh '''
          . /home/ubuntu/openrc.sh
          terraform ${ACTION} -auto-approve
        '''
      }
    }
  }
  
  post {
    success {
      echo "✅ Terraform ${ACTION} completed successfully"
    }
    failure {
      echo "❌ Terraform ${ACTION} failed"
    }
  }
}
