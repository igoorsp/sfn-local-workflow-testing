# Meu Projeto de Step Functions

Este projeto demonstra como orquestrar um fluxo **Step Functions** com padrão de callback (via SQS).

## Estrutura
- **infra/**: Definições de infraestrutura (Step Functions, filas SQS, etc.).
- **scripts/**: Scripts para iniciar/parar ambiente local, deploy, etc.
- **tests/**: Testes unitários e de integração.

## Requisitos
- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## Como rodar localmente
1. Suba o LocalStack:
    ```bash
    docker-compose up -d
    ```
2. Crie recursos (fila SQS, Step Functions) no LocalStack:
    ```bash
    bash scripts/start-local.sh
    ```
3. Execute os testes:
    ```bash
    pytest tests/
    ```
4. Para encerrar:
    ```bash
    docker-compose down
    ```

## Deploy na AWS (exemplo com SAM ou CDK)
- Consulte [infra/cdk/README.md](infra/cdk/README.md) (ou outro local) para instruções.

## Contribuições
- Forke o repositório, crie uma branch e abra um Pull Request.
- Qualquer dúvida, abra uma Issue.

## Licença
[MIT](LICENSE)



