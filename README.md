(Due to technical issues, the search service is temporarily unavailable.)

Aqui está a versão atualizada do documento, com a alteração solicitada no item **"Sequência de Comandos para Configuração do Ambiente Local"**. Apenas essa seção foi modificada, mantendo o restante do conteúdo intacto.

---

# Documentação de Arquitetura: Desenvolvimento Local para Cenários AWS Step Functions

Este documento descreve a estrutura e os procedimentos para configurar e testar um ambiente local que simula o uso de **AWS Step Functions** com o padrão de callback via **SQS (Simple Queue Service)**. O ambiente é montado utilizando o **LocalStack**, uma ferramenta que emula serviços da AWS localmente.

---

## Sumário

1. [Estrutura do Projeto](#estrutura-do-projeto)
2. [Requisitos](#requisitos)
3. [LocalStack](#localstack)
   - [Arquivo `docker-compose.yml`](#arquivo-docker-composeyml)
   - [Executando o LocalStack](#executando-o-localstack)
4. [AWS SQS](#aws-sqs)
   - [Criar Queue no AWS SQS](#criar-queue-no-aws-sqs)
   - [Listar Queues SQS](#listar-queues-sqs)
   - [Verificar Attributes da Queue](#verificar-attributes-da-queue)
5. [AWS DynamoDB](#aws-dynamodb)
   - [Criar Tabela no DynamoDB](#criar-tabela-no-dynamodb)
   - [Listar Tabelas Criadas no DynamoDB](#listar-tabelas-criadas-no-dynamodb)
6. [AWS Lambda](#aws-lambda)
   - [Criar uma Function](#criar-uma-function)
   - [Listar Funções Lambda](#listar-funções-lambda)
   - [Verificar Detalhes da Lambda](#verificar-detalhes-da-lambda)
7. [Verificar o Trigger da Lambda (Event Source Mapping)](#verificar-o-trigger-da-lambda-event-source-mapping)
   - [Listar Event Source Mappings](#listar-event-source-mappings)
   - [Verificar Detalhes do Trigger](#verificar-detalhes-do-trigger)
8. [Verificar a Step Function](#verificar-a-step-function)
   - [Listar Step Functions](#listar-step-functions)
   - [Verificar Detalhes da Step Function](#verificar-detalhes-da-step-function)
9. [Testar o Fluxo Completo](#testar-o-fluxo-completo)
   - [Enviar uma Mensagem para a Fila SQS](#enviar-uma-mensagem-para-a-fila-sqs)
   - [Verificar os Logs da Lambda](#verificar-os-logs-da-lambda)
   - [Iniciar uma Execução da Step Function](#iniciar-uma-execução-da-step-function)
   - [Verificar o Status da Execução](#verificar-o-status-da-execução)
10. [Sequência de Comandos para Configuração do Ambiente Local](#sequência-de-comandos-para-configuração-do-ambiente-local)
11. [Resumo](#resumo)

---

## Estrutura do Projeto

O projeto é organizado da seguinte forma:

- **`infrastructure/`**: Contém o arquivo **`docker-compose.yml`** com a configuração dos serviços do LocalStack.
- **`src/`**: Contém o código-fonte das **AWS Lambda**, scripts para inicializar o ambiente e a definição da **State Machine** do AWS Step Functions.

---

## Requisitos

Para executar o projeto localmente, são necessários os seguintes requisitos:

- **Docker**
- **Docker Compose**
- **AWS CLI**
- **Imagem Docker LocalStack (`localstack/localstack:latest`)**

---

## LocalStack

O **LocalStack** é uma ferramenta que emula serviços da AWS localmente, permitindo o desenvolvimento e teste de aplicações sem a necessidade de acessar a AWS real.

### Arquivo `docker-compose.yml`

O arquivo `docker-compose.yml` configura o LocalStack com os serviços necessários:

```yaml
version: "3.8"
services:
  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"  # Porta padrão do LocalStack
      - "8080:8080"  # Porta da interface web (opcional)
    environment:
      - SERVICES=sqs,lambda,stepfunctions,dynamodb,s3,events,sts  # Serviços habilitados
      - DEFAULT_REGION=us-east-1
      - DEBUG=1
    volumes:
      - ./localstack-data:/tmp/localstack  # Persistência de dados
```

### Executando o LocalStack

Para iniciar o LocalStack, execute o seguinte comando:

```bash
docker-compose up --build -d
```

![Executando o LocalStack](/images/docker-compose-up.png)

---

## AWS SQS

O **Amazon SQS** é um serviço de filas gerenciado que permite a comunicação assíncrona entre componentes de uma aplicação.

### Criar Queue no AWS SQS

Para criar uma fila SQS, utilize o seguinte comando:

```bash
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name DynamoQueue
```

![Criar Queue no SQS](/images/sqs/create-new-sqs-queue.png)

- **`aws --endpoint-url=http://localhost:4566`**: Define que o comando será executado no LocalStack.
- **`sqs create-queue --queue-name DynamoQueue`**: Cria uma fila SQS chamada `DynamoQueue`.

### Listar Queues SQS

Para listar as filas SQS criadas, execute:

```bash
aws --endpoint-url=http://localhost:4566 sqs list-queues
```

Saída esperada:

```json
{
    "QueueUrls": [
        "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/DynamoQueue"
    ]
}
```

![Listar Queues SQS](/images/sqs/list-sqs-queue.png)

### Verificar Attributes da Queue

Para obter detalhes sobre uma fila SQS, utilize:

```bash
aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/DynamoQueue \
    --attribute-names All
```

![Verificar Attributes da Queue](/images/sqs/get-attribute-sqs-queue.png)

---

## AWS DynamoDB

O **Amazon DynamoDB** é um banco de dados NoSQL gerenciado que oferece desempenho rápido e escalável.

### Criar Tabela no DynamoDB

Para criar uma tabela no DynamoDB, utilize:

```bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name human-task-control \
    --attribute-definitions AttributeName=executionId,AttributeType=S \
    --key-schema AttributeName=executionId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

![Criar Tabela no DynamoDB](/images/dynamodb/create-dynamodb.png)

### Listar Tabelas Criadas no DynamoDB

Para listar as tabelas criadas, execute:

```bash
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

![Listar Tabelas no DynamoDB](/images/dynamodb/list-tables-dynamodb.png)

---

## AWS Lambda

O **AWS Lambda** é um serviço de computação sem servidor que executa código em resposta a eventos.

### Criar uma Function

Para criar uma função Lambda, utilize:

```bash
aws --endpoint-url=http://localhost:4566 lambda create-function \
    --function-name sqs-handler \
    --runtime provided.al2 \
    --handler bootstrap \
    --zip-file fileb://../../src/lambda/sqs-hanlder/target/function.zip \
    --role arn:aws:iam::000000000000:role/service-role/lambda-role \
    --region us-east-1
```

![Criar Function Lambda](/images/lambda/create-function.png)

### Listar Funções Lambda

Para listar as funções Lambda criadas, execute:

```bash
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

![Listar Funções Lambda](/images/lambda/list-function.png)

### Verificar Detalhes da Lambda

A saída esperada ao listar as funções Lambda é:

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

## Verificar o Trigger da Lambda (Event Source Mapping)

### Listar Event Source Mappings

Para listar os mapeamentos de eventos (triggers) da Lambda, execute:

```bash
aws --endpoint-url=http://localhost:4566 lambda list-event-source-mappings
```

### Verificar Detalhes do Trigger

A saída esperada é:

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

## Verificar a Step Function

### Listar Step Functions

Para listar as Step Functions criadas, execute:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions list-state-machines
```

### Verificar Detalhes da Step Function

A saída esperada é:

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

## Testar o Fluxo Completo

### Enviar uma Mensagem para a Fila SQS

Para enviar uma mensagem para a fila SQS, utilize:

```bash
aws --endpoint-url=http://localhost:4566 sqs send-message \
    --queue-url http://localhost:4566/000000000000/SQSQueue1 \
    --message-body "Teste de mensagem SQS"
```

### Verificar os Logs da Lambda

Para verificar os logs da Lambda, execute:

```bash
aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/sqs-handler
```

Saída esperada:

```
Evento recebido: {'Records': [{'body': 'Teste de mensagem SQS', ...}]}
Mensagem processada: Teste de mensagem SQS
```

### Iniciar uma Execução da Step Function

Para iniciar uma execução da Step Function, utilize:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions start-execution \
    --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:CallbackPatternStateMachine \
    --input '{"businessKey": "123"}'
```

### Verificar o Status da Execução

Para verificar o status da execução, utilize:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
    --execution-arn <ARN_DA_EXECUCAO>
```

Substitua `<ARN_DA_EXECUCAO>` pelo ARN da execução retornado no comando anterior.

---

## Sequência de Comandos para Configuração do Ambiente Local

Esta seção apresenta uma sequência de comandos para configurar e testar o ambiente local de forma rápida e eficiente.

### 1. Iniciar o LocalStack

```bash
docker compose -f infrastructure/localstack/docker-compose.yml up -d --build
```

### 2. Configurar o SQS

#### Criar uma Fila SQS

```bash
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name DynamoQueue
```

#### Listar Filas SQS

```bash
aws --endpoint-url=http://localhost:4566 sqs list-queues
```

### 3. Configurar o AWS Lambda

#### Criar uma Função Lambda

```bash
aws --endpoint-url=http://localhost:4566 lambda create-function \
    --function-name sqs-handler \
    --runtime provided.al2 \
    --handler bootstrap \
    --zip-file fileb://src/lambda/sqs-hanlder/target/function.zip \
    --role arn:aws:iam::000000000000:role/service-role/lambda-role \
    --region us-east-1
```

#### Listar Funções Lambda

```bash
aws --endpoint-url=http://localhost:4566 lambda list-functions
```

### 4. Configurar o Trigger da Lambda com SQS

#### Obter o ARN da Fila SQS

```bash
QUEUE_ARN=$(aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/DynamoQueue \
    --attribute-names QueueArn \
    --query Attributes.QueueArn \
    --output text)
```

#### Criar o Event Source Mapping

```bash
aws --endpoint-url=http://localhost:4566 lambda create-event-source-mapping \
    --function-name sqs-handler \
    --event-source-arn arn:aws:sqs:us-east-1:000000000000:DynamoQueue \
    --batch-size 10
```

#### Listar Event Source Mappings

```bash
aws --endpoint-url=http://localhost:4566 lambda list-event-source-mappings
```

### 5. Enviar uma Mensagem para a Fila SQS

```bash
aws --endpoint-url=http://localhost:4566 sqs send-message \
  --queue-url http://localhost:4566/000000000000/DynamoQueue \
  --message-body '{"businessKey":"my-business-key-01"}'
```

### 6. Configurar o DynamoDB

#### Criar uma Tabela no DynamoDB

```bash
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
    --table-name human-task-control \
    --attribute-definitions AttributeName=executionId,AttributeType=S \
    --key-schema AttributeName=executionId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

#### Verificar Dados na Tabela

```bash
aws --endpoint-url=http://localhost:4566 dynamodb scan \
    --table-name human-task-control
```

### 7. Configurar o AWS Step Functions

#### Criar uma State Machine

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions create-state-machine \
    --name CallbackPatternStateMachine \
    --definition file://src/statemachines/callback-pattern.asl.json \
    --role-arn arn:aws:iam::000000000000:role/service-role/StepFunctions-Local
```

#### Iniciar uma Execução da State Machine

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions start-execution \
    --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:CallbackPatternStateMachine \
    --input '{"businessKey": "my-business-key-01"}'
```

#### Verificar o Status da Execução

Substitua `<ARN_DA_EXECUCAO>` pelo ARN da execução retornado no comando anterior:

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
    --execution-arn <ARN_DA_EXECUCAO>
```

#### Excluir uma State Machine

```bash
aws --endpoint-url=http://localhost:4566 stepfunctions delete-state-machine \
    --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:CallbackPatternStateMachine
```

### 8. Verificar Logs

#### Verificar Logs da Lambda

```bash
aws --endpoint-url=http://localhost:4566 logs tail /aws/lambda/sqs-handler
```

#### Verificar Logs do LocalStack

```bash
docker logs localstack
```

### 9. Encerrar o Ambiente

```bash
docker compose -f infrastructure/localstack/docker-compose.yml down
```

---

## Resumo

Este documento descreve como configurar e testar um ambiente local para simular o uso de **AWS Step Functions** com o padrão de callback via **SQS**. Utilizando o **Local