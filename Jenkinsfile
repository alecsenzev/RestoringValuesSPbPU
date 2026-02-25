pipeline {
  agent { label 'Nikita_Alecsentsev' }

  parameters {
    string(name: 'TARGET_HOST', defaultValue: '192.168.199.71', description: 'Server with Docker')
    string(name: 'REGISTRY_PORT', defaultValue: '5000', description: 'Registry port')
  }

  stages {
    stage('Check Docker on server') {
      steps {
        sh '''
          ssh -i /home/ubuntu/Nikita_Alecsentsev.pem -o StrictHostKeyChecking=no debian@${TARGET_HOST} "
            docker --version || echo 'Docker not found'
          "
        '''
      }
    }

    stage('Start Docker Registry') {
      steps {
        sh '''
          ssh -i /home/ubuntu/Nikita_Alecsentsev.pem debian@${TARGET_HOST} "
            # Проверяем запущен ли registry
            if ! docker ps | grep registry; then
              echo 'Starting Docker registry on port ${REGISTRY_PORT}...'
              docker run -d -p ${REGISTRY_PORT}:5000 --name registry registry:2
            else
              echo 'Registry already running'
            fi
          "
        '''
      }
    }

    stage('Build and push test image') {
      steps {
        sh '''
          ssh -i /home/ubuntu/Nikita_Alecsentsev.pem debian@${TARGET_HOST} "
            # Создаем простой Dockerfile для теста
            mkdir -p ~/registry-test
            cd ~/registry-test
            
            cat > Dockerfile << EOF
FROM alpine:latest
CMD echo 'Hello from Docker Registry Lab'
EOF
            
            # Собираем образ
            docker build -t localhost:${REGISTRY_PORT}/test-lab6:latest .
            
            # Пушим в registry
            docker push localhost:${REGISTRY_PORT}/test-lab6:latest
          "
        '''
      }
    }

    stage('Verify registry') {
      steps {
        sh '''
          ssh -i /home/ubuntu/Nikita_Alecsentsev.pem debian@${TARGET_HOST} "
            # Проверяем содержимое registry
            curl -s http://localhost:${REGISTRY_PORT}/v2/_catalog | python3 -m json.tool || echo 'Registry not responding'
            
            # Скачиваем образ обратно
            docker rmi localhost:${REGISTRY_PORT}/test-lab6:latest || true
            docker pull localhost:${REGISTRY_PORT}/test-lab6:latest
          "
        '''
      }
    }
    
    stage('Push AI-bot image (if exists)') {
      steps {
        sh '''
          ssh -i /home/ubuntu/Nikita_Alecsentsev.pem debian@${TARGET_HOST} "
            # Проверяем есть ли образ ai-bot
            if docker images | grep ai-bot; then
              docker tag ai-bot:latest localhost:${REGISTRY_PORT}/ai-bot:latest
              docker push localhost:${REGISTRY_PORT}/ai-bot:latest
              echo '✅ AI-bot image pushed to registry'
            else
              echo '⚠️ AI-bot image not found, skipping...'
            fi
          "
        '''
      }
    }
  }

  post {
    always {
      echo "✅ Lab 6 pipeline completed"
    }
    success {
      echo "🎉 Docker Registry is available on ${TARGET_HOST}:${REGISTRY_PORT}"
    }
  }
}
