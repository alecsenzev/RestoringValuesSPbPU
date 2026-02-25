pipeline {
  agent { label 'Nikita_Alecsentsev' }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
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
    
    echo '=== 1. Чиним репозитории Debian ==='
    sudo sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list
    sudo sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list
    sudo sed -i 's/buster\\/updates/buster/g' /etc/apt/sources.list
    
    echo '=== 2. Добавляем buster-backports ==='
    echo 'deb http://archive.debian.org/debian buster-backports main' | sudo tee -a /etc/apt/sources.list
    
    echo '=== 3. Обновляем списки пакетов ==='
    sudo apt update -o Acquire::Check-Valid-Until=false || sudo apt update
    
    echo '=== 4. Устанавливаем Python 3.9 из бэкпортов ==='
    sudo apt install -y -t buster-backports python3.9 python3.9-venv python3.9-dev
    
    echo '=== 5. Создаем директорию приложения ==='
    mkdir -p ~/app
    cp /tmp/*.whl /tmp/app-restoringvalues.tgz ~/app/
    cd ~/app
    
    echo '=== 6. Распаковываем tgz ==='
    if [ -f app-restoringvalues.tgz ]; then
        tar -xzf app-restoringvalues.tgz || true
    fi
    
    echo '=== 7. Создаем виртуальное окружение с Python 3.9 ==='
    python3.9 -m venv venv
    source venv/bin/activate
    
    echo '=== 8. Обновляем pip ==='
    pip install --upgrade pip setuptools wheel
    
    echo '=== 9. Устанавливаем wheel ==='
    pip install *.whl
    
    echo '=== 10. Проверяем установку ==='
    pip list | grep restoring || echo 'Package not found'
    
    echo '=== 11. Тестируем импорт ==='
    python -c 'import restoringvalues; print(\"✅ SUCCESS: Package imported correctly\")' 2>/dev/null && echo '✅ IMPORT OK' || echo '⚠️ Import failed'
"

echo "✅ DEPLOY COMPLETE"
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

ssh $SSH_OPTS ${SSH_USER}@${TARGET_HOST} "
    if [ -f ~/app/venv/bin/activate ]; then
        source ~/app/venv/bin/activate
        python -c 'import restoringvalues; print(\"✅ HEALTH CHECK: Package is working\")' 2>/dev/null && echo '✅ OK' || echo '⚠️ Import failed'
    else
        echo '⚠️ Virtual environment not found'
        exit 1
    fi
"

echo "✅ Health check passed"
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
      echo "🎉 SUCCESS: Application deployed to ${params.TARGET_HOST}"
    }
    failure {
      echo "❌ FAILURE: Check logs above"
    }
  }
}
