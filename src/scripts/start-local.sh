#!/bin/bash

# Configurações
AWS_ENDPOINT="http://localhost:4566"
REGION="us-east-1"
QUEUE_NAME="SQSQueue1"
LAMBDA_NAME="sqs-handler"
STATE_MACHINE_NAME="CallbackPatternStateMachine"
STATE_MACHINE_DEFINITION="file://../statemachines/callback-pattern.asl.json"
LAMBDA_ZIP_PATH="../lambda/sqs-hanlder/target/function.zip"  # Caminho para o ZIP gerado na compilação

# Cria a fila SQS
echo "Criando fila SQS: $QUEUE_NAME"
aws --endpoint-url=$AWS_ENDPOINT sqs create-queue --queue-name $QUEUE_NAME --region $REGION

# Cria a Lambda
echo "Criando Lambda: $LAMBDA_NAME"
aws --endpoint-url=$AWS_ENDPOINT lambda create-function \
    --function-name $LAMBDA_NAME \
    --runtime provided.al2 \
    --handler bootstrap \
    --zip-file fileb://$LAMBDA_ZIP_PATH \
    --role arn:aws:iam::000000000000:role/service-role/lambda-role \
    --region $REGION

echo "Lambda criada com sucesso!"

# Cria o Event Source Mapping (Trigger da Lambda pela fila SQS)
echo "Configurando trigger da Lambda pela fila SQS"
QUEUE_ARN=$(aws --endpoint-url=$AWS_ENDPOINT sqs get-queue-attributes \
    --queue-url $AWS_ENDPOINT/000000000000/$QUEUE_NAME \
    --attribute-names QueueArn \
    --query Attributes.QueueArn \
    --output text \
    --region $REGION)
aws --endpoint-url=$AWS_ENDPOINT lambda create-event-source-mapping \
    --function-name $LAMBDA_NAME \
    --event-source-arn $QUEUE_ARN \
    --batch-size 10 \
    --region $REGION

# Cria a Step Function
echo "Criando Step Function: $STATE_MACHINE_NAME"
aws --endpoint-url=$AWS_ENDPOINT stepfunctions create-state-machine \
    --name $STATE_MACHINE_NAME \
    --definition $STATE_MACHINE_DEFINITION \
    --role-arn arn:aws:iam::000000000000:role/service-role/StepFunctions-Local \
    --region $REGION

echo "Ambiente local configurado com sucesso!"