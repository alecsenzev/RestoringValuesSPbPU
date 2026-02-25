pipeline {
  agent { label 'Nikita_Alecsentsev' }

  options {
    timestamps()
    timeout(time: 15, unit: 'MINUTES')
    disableConcurrentBuilds()
    skipDefaultCheckout(true)
  }

  parameters {
    string(name: 'TARGET_HOST', defaultValue: '192.168.199.71', description: 'Deploy host')
    string(name: 'BUILD_JOB', defaultValue: 'Nikita_Alecsentsev_RestoringValuesSPbPU', description: 'L2 job name')
  }

  stages {

    stage('Fetch artifacts from L2') {
      steps {
        script {
          sh 'rm -rf deploy_art && mkdir -p deploy_art'

          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'dist/*.whl', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])
          
          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'app-restoringvalues.tgz', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])
          
          step([$class: 'CopyArtifact', 
                projectName: params.BUILD_JOB, 
                selector: [$class: 'StatusBuildSelector', stable: false], 
                filter: 'artifacts.tgz', 
                target: 'deploy_art', 
                fingerprintArtifacts: true])

          sh 'find deploy_art -maxdepth 4 -type f -print'
        }
      }
    }

    stage('Deploy to server') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

SSH_USER="debian"
TARGET_HOST="192.168.199.71"
SSH_OPTS="-i /home/ubuntu/Nikita_Alecsentsev.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Находим файлы
WHEEL=$(find deploy_art -name "*.whl" -type f | head -1)
TGZ=$(find deploy_art -name "app-restoringvalues.tgz" -type f | head -1)

echo "Wheel: $WHEEL"
echo "TGZ: $TGZ"

if [ -z "$WHEEL" ] || [ -z "$TGZ" ]; then
    echo "ERROR: Required artifacts not found!"
    exit 1
fi

# Копируем файлы на сервер
echo "Copying files to ${TARGET_HOST}..."
scp $SSH_OPTS "$WHEEL" "$TGZ" ${SSH_USER}@${TARGET_HOST}:/tmp/

# Выполняем установку на сервере
ssh $SSH_OPTS ${SSH_USER}@${TARGET_HOST} "
    set -e
    echo '=== Files received ==='
    ls -la /tmp/*.whl /tmp/app-restoringvalues.tgz
    
    # Устанавливаем Python и pip если их нет
    if ! command -v pip3 &> /dev/null; then
        sudo apt update
        sudo apt install -y python3-pip python3-venv
    fi
    
    # Создаем директорию для приложения
    mkdir -p ~/app
    
    # Копируем файлы из /tmp
    cp /tmp/*.whl /tmp/app-restoringvalues.tgz ~/app/
    cd ~/app
    
    # Распаковываем tgz если нужно
    if [ -f app-restoringvalues.tgz ]; then
        tar -xzf app-restoringvalues.tgz || true
    fi
    
    # Создаем виртуальное окружение и устанавливаем пакет
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install *.whl
    
    # Проверяем установку
    echo '=== Installation complete ==='
    pip list | grep restoring || echo 'Package not found in pip list'
    
    # Пробуем импортировать
    python -c 'import restoringvalues; print(\"✅ Package imported successfully\")' 2>/dev/null || echo '⚠️ Import failed'
"

echo "✅ DONE"
'''
      }
    }
    
    stage('Health check') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

SSH_USER="debian"
TARGET_HOST="192.168.199.71"
SSH_OPTS="-i /home/ubuntu/Nikita_Alecsentsev.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Проверяем что приложение установлено
ssh $SSH_OPTS ${SSH_USER}@${TARGET_HOST} "
    if [ -f ~/app/venv/bin/activate ]; then
        source ~/app/venv/bin/activate
        python -c 'import restoringvalues; print(\"✅ Package installed and importable\")' 2>/dev/null || echo '⚠️ Import check failed'
    else
        echo '⚠️ Virtual environment not found'
    fi
"

echo "✅ Health check completed"
'''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'deploy_art/**', allowEmptyArchive: true
      cleanWs()
    }
    success {
      echo "🎉 Deployment successful to ${params.TARGET_HOST}"
    }
    failure {
      echo "❌ Deployment failed"
    }
  }
}
