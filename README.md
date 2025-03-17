# Desenvolvimento Local para cenarios AWS Step Functions

Este projeto demonstra como orquestrar um fluxo **Step Functions** com padrão de callback (via SQS) e como montar o ambiente local para "simular".

## Estrutura do Projeto
- **infrastructure/**: Arquivo **docker-compose.yml** com os serico
- **src/**: Codigo fonte das AWS Lambda, script para inicializar o ambiente e a definicao da State Machine do AWS Step Functions.

## Requisitos
- **Docker**
- **Docker Compose**
- **AWS CLI**
- **Imagem Docker LocalStack (localstack/localstack:latest)**

## **LocalStack**

### **Arquivo docker-compose**
```yml
version: "3.8"
services:
  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"  # Porta padrão do LocalStack
      - "8080:8080"  # Porta da interface web (opcional)
    environment:
      - SERVICES=sqs,lambda,stepfunctions,dynamodb,s3,events,sts  # Adicione os servicos necessarios em SERVICES.
      - DEFAULT_REGION=us-east-1
      - DEBUG=1
    volumes:
      - ./localstack-data:/tmp/localstacks  # Persistência de dados
```

### **Executando**
```bash
docker-compose up --build -d
```
![alt](/images/docker-compose-up.png)

## **AWS SQS**

### **Criar Queue no AWS SQS**
Para criar uma Queue, usar o comando abaixo:

```bash
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name DynamoQueue
```
![alt](/images/sqs/create-new-sqs-queue.png)
-

- **aws --endpoint-url=http://localhost:4566**: Aqui estamos dizendo ao AWS CLI para não enviar a requisição aos servidores da AWS, mas sim para o endpoint local do LocalStack (que está em http://localhost:4566).
- **sqs create-queue --queue-name DynamoQueue**: É um comando da AWS CLI para criar uma fila no serviço SQS. Neste caso, como o endpoint-url aponta para o LocalStack, a fila é criada no ambiente local do LocalStack, em vez da AWS “real”.


### **Listar Queues SQS**
Execute o seguinte comando para listar as Queues SQS criadas:

```bash
aws --endpoint-url=http://localhost:4566 sqs list-queues
```

```json
{
    "QueueUrls": [
        "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/DynamoQueue"
    ]
}

```

![alt](/images/sqs/list-sqs-queue.png)


### **Verificar Attributes da Queue**

Para ver mais detalhes sobre a Queue, use:

```bash
aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/DynamoQueue \
    --attribute-names All
```
![alt](/images/sqs/get-attribute-sqs-queue.png)

---

## **AWS DynamoDB**

### **Criar tabela no DynamoDB**

```bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name human-task-control \
    --attribute-definitions AttributeName=executionId,AttributeType=S \
    --key-schema AttributeName=executionId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```
![alt](/images/dynamodb/create-dynamodb.png)

### **Listar tabelas criadas no DynamoDB**

```bash
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```
![alt](/images/dynamodb/list-tables-dynamodb.png)
    
## **AWS Lambda**

### **Criar uma Function**
Execute o seguinte comando para criar uma Funcao Lambda:
```bash
aws --endpoint-url=http://localhost:4566 lambda create-function \
    --function-name sqs-handler \
    --runtime provided.al2 \
    --handler bootstrap \
    --zip-file fileb://../../src/lambda/sqs-hanlder/target/function.zip \
    --role arn:aws:iam::000000000000:role/service-role/lambda-role \
    --region us-east-1
    
```
![alt](/images/lambda/create-function.png)


### **Listar Funções Lambda**
Execute o seguinte comando para listar as funções Lambda criadas:

```bash
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

![alt](/images/lambda/list-function.png)


### **Verificar Detalhes da Lambda**
Se a Lambda foi criada corretamente, você verá uma saída como esta:

```json
{
    "Functions": [
        {
            "FunctionName": "sqs-handler",
            "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:sqs-handler",
            "Runtime": "provided.al2",
            "Role": "arn:aws:iam::000000000000:role/service-role/lambda-role",
            "Handler": "bootstrap",
            "CodeSize": 22059552,
            "Description": "",
            "Timeout": 3,
            "MemorySize": 128,
            "LastModified": "2025-03-14T19:36:57.988933+0000",
            "CodeSha256": "Vynz19Ja9HHFs8C5a7LfZ9EuHl+GpgrLco1zf9c9Ea8=",
            "Version": "$LATEST",
            "TracingConfig": {
                "Mode": "PassThrough"
            },
            "RevisionId": "73c951d2-9916-44bc-a493-c8231e41435a",
            "PackageType": "Zip",
            "Architectures": [
                "x86_64"
            ],
            "EphemeralStorage": {
                "Size": 512
            },
            "SnapStart": {
                "ApplyOn": "None",
                "OptimizationStatus": "Off"
            },
            "LoggingConfig": {
                "LogFormat": "Text",
                "LogGroup": "/aws/lambda/sqs-handler"
            }
        }
    ]
}

```

---

## **Verificar o Trigger da Lambda (Event Source Mapping)**

### **Listar Event Source Mappings**
Execute o seguinte comando para listar os mapeamentos de eventos (triggers) da Lambda:

```bash
aws --endpoint-url=http://localhost:4566 lambda list-event-source-mappings
```

### **Verificar Detalhes do Trigger**
Se o trigger foi criado corretamente, você verá uma saída como esta:

```json
{
    "EventSourceMappings": [
        {
            "UUID": "12345678-1234-5678-1234-567812345678",
            "EventSourceArn": "arn:aws:sqs:us-east-1:000000000000:SQSQueue1",
            "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:sqs-handler",
            "State": "Enabled",
            "BatchSize": 10
        }
    ]
}
```

---

## **Verificar a Step Function**

### **Listar Step Functions**
Execute o seguinte comando para listar as Step Functions criadas:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions list-state-machines
```

### **Verificar Detalhes da Step Function**
Se a Step Function foi criada corretamente, você verá uma saída como esta:

```json
{
    "stateMachines": [
        {
            "stateMachineArn": "arn:aws:states:us-east-1:000000000000:stateMachine:CallbackPatternStateMachine",
            "name": "CallbackPatternStateMachine",
            "creationDate": "2025-03-14T12:00:00.000Z"
        }
    ]
}
```

---

## **Testar o Fluxo Completo**

### **Enviar uma Mensagem para a Fila SQS**
Envie uma mensagem para a fila SQS para acionar a Lambda:

```bash
aws --endpoint-url=http://localhost:4566 sqs send-message \
    --queue-url http://localhost:4566/000000000000/SQSQueue1 \
    --message-body "Teste de mensagem SQS"
```

### **Verificar os Logs da Lambda**
Verifique os logs da Lambda para confirmar que a mensagem foi processada:

```bash
aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/sqs-handler
```

Você verá algo como:

```
Evento recebido: {'Records': [{'body': 'Teste de mensagem SQS', ...}]}
Mensagem processada: Teste de mensagem SQS
```

---

## **Verificar a Step Function**

### **Iniciar uma Execução da Step Function**
Inicie uma execução da Step Function:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions start-execution \
    --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:CallbackPatternStateMachine \
    --input '{"businessKey": "123"}'
```

### **Verificar o Status da Execução**
Verifique o status da execução:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
    --execution-arn <ARN_DA_EXECUCAO>
```

Substitua `<ARN_DA_EXECUCAO>` pelo ARN da execução retornado no comando anterior.

---

## **Resumo**

- **Fila SQS**: Verifique se a fila foi criada e se as mensagens são processadas.
- **Lambda**: Verifique se a Lambda foi criada e se está sendo acionada pela fila SQS.
- **Step Function**: Verifique se a Step Function foi criada e se as execuções estão funcionando corretamente.

Com esses passos, você pode confirmar que todos os recursos foram criados e configurados corretamente no LocalStack. 🚀



