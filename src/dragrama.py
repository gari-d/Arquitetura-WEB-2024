from diagrams import Cluster, Diagram
from diagrams.aws.compute import ECS, Lambda
from diagrams.aws.database import RDS, Redshift
from diagrams.aws.integration import SQS
from diagrams.aws.network import ALB, Route53
from diagrams.aws.storage import S3
from diagrams.onprem.client import User 

with Diagram("Loja de Jogos Retrô", show=False):
    cliente = User("Cliente")  # Ícone de usuário representando o cliente
    dns = Route53("DNS (Route 53)")  # DNS do Route 53

    with Cluster("Camada Web"):
        balanceador = ALB("Balanceador de Carga")
        servidores_web = [ECS("Servidor Web 1"),
                          ECS("Servidor Web 2")]

    with Cluster("Camada de Aplicação"):
        servidores_aplicacao = [ECS("Servidor de Aplicação 1"),
                                ECS("Servidor de Aplicação 2")]

    with Cluster("Processamento de Eventos"):
        fila = SQS("Fila de Pedidos")

        with Cluster("Manipuladores de Pedidos"):
            manipuladores = [Lambda("Processador de Pagamento"),
                             Lambda("Verificação de Inventário"),
                             Lambda("Confirmação de Pedido")]

    with Cluster("Camada de Dados"):
        banco_dados = RDS("Banco de Dados de Usuários")
        armazenamento_jogos = S3("Armazenamento de Jogos")
        analise = Redshift("Análise de Vendas")

    # Fluxo de Requisição do Cliente
    cliente >> dns >> balanceador
    for servidor_web in servidores_web:
        balanceador >> servidor_web
        servidor_web >> servidores_aplicacao

    # Fluxo de Processamento de Pedidos
    for servidor_aplicacao in servidores_aplicacao:
        servidor_aplicacao >> fila
    for manipulador in manipuladores:
        fila >> manipulador
        manipulador >> armazenamento_jogos
        manipulador >> banco_dados
        manipulador >> analise
