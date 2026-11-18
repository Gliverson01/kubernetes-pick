# Day 03 - Deployment, ReplicaSet e selector

**Data:** 2026-11-16

## Deployment

[deployment.yaml](deployment.yaml): Deployment `nginx-deployment` com 3 réplicas de `nginx`, com requests e limits.

- O Deployment é o jeito certo de rodar uma aplicação no cluster, em vez de criar pods soltos: ele mantém o número de réplicas e cuida das atualizações.

> **Complemento:** o Deployment não cria os pods direto. A hierarquia é:
>
> ```
> Deployment → ReplicaSet → Pods
> ```
>
> - O **ReplicaSet** é quem garante que existam sempre 3 pods (`replicas: 3`). Se um morrer, ele cria outro.
> - Quando o Deployment muda (ex.: imagem nova), ele cria um **ReplicaSet novo** e vai trocando os pods aos poucos (**rolling update**, o padrão do `strategy`).
> - O ReplicaSet antigo fica guardado com 0 pods. É isso que permite voltar a versão anterior.

```bash
kubectl apply -f day-03/deployment.yaml
kubectl get deploy,rs,pods                        # o nome do pod = nome do ReplicaSet + sufixo
kubectl rollout status deploy nginx-deployment
kubectl rollout history deploy nginx-deployment   # revisões guardadas
kubectl rollout undo deploy nginx-deployment      # volta para a revisão anterior
```

## Selector

- O `selector` representa os pods que o Deployment vai manipular: ele controla os pods que têm as labels do `matchLabels`.

```yaml
spec:
  selector:
    matchLabels:
      app: nginx-deployment     # quais pods o Deployment controla
  template:
    metadata:
      labels:
        app: nginx-deployment   # labels que os pods novos recebem
```

> **Correção:** o selector **tem que bater** com as labels do `template`. Se não bater, o `kubectl apply` dá erro.
>
> Não é "um Deployment para cada label de pod". A boa prática é **um Deployment por aplicação**, e dois Deployments **não podem ter selectors que peguem os mesmos pods**, senão um briga com o outro (um cria, o outro apaga).

```bash
kubectl get pods --show-labels
kubectl get pods -l app=nginx-deployment   # filtra pelos mesmos labels do selector
```

## Infraestrutura versionada

- Alteração na infraestrutura se faz no arquivo do Deployment, não via comando direto no terminal. Assim fica persistido e com histórico no Git.

> **Complemento:** isso é a diferença entre os dois jeitos de trabalhar:
> - **Imperativo:** dar a ordem pelo terminal (`kubectl scale deploy nginx-deployment --replicas=5`). Funciona, mas a mudança não fica registrada e o YAML deixa de bater com o cluster.
> - **Declarativo:** mudar o YAML, commitar e rodar `kubectl apply -f`. O Git vira o histórico de quem mudou o quê e quando.
>
> Levado ao extremo, isso é **GitOps**: uma ferramenta como o **ArgoCD** aplica sozinha no cluster o que está no Git. O imperativo continua útil para testar ou numa emergência, mas o que vale é o arquivo.

> **Obs.:** o `strategy: {}` no YAML é sobra do `--dry-run`. Vazio, usa o padrão (`RollingUpdate`).

## Namespace

[namespace.yaml](namespace.yaml): namespace `glipops`. O Deployment passou a ser criado nele (`metadata.namespace: glipops`).

- Namespace separa os recursos do cluster em "pastas": o mesmo nome de Deployment pode existir em namespaces diferentes.

> **Complemento:** o namespace tem que existir **antes** do Deployment, senão o apply dá `namespaces "glipops" not found`. Sem `-n`, o kubectl olha o namespace `default`, por isso o Deployment "some" do `kubectl get pods`.

```bash
kubectl apply -f day-03/namespace.yaml
kubectl apply -f day-03/deployment.yaml
kubectl get pods -n glipops
kubectl config set-context --current --namespace=glipops   # deixa o glipops como padrão
```

## Estratégia de atualização

Subi o Deployment para **10 réplicas** com a imagem `nginx:1.15.0` e configurei o `strategy`:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

- **RollingUpdate:** a atualização é parcial, vai trocando os pods aos poucos.
- **Recreate:** a atualização é completa, derruba todos os pods antigos e depois sobe os novos.
- `kubectl rollout status` mostra o andamento da atualização.

> **Complemento:**
> - **maxSurge: 1** = pode ter até **1 pod a mais** que o `replicas` durante a troca (até 11).
> - **maxUnavailable: 1** = pode ter até **1 pod a menos** disponível (no mínimo 9 no ar).
> - Os dois aceitam número ou porcentagem (o padrão é `25%`).
> - O **Recreate** deixa a aplicação fora do ar entre derrubar e subir. Serve quando duas versões não podem rodar juntas (ex.: migração de banco que quebra a versão antiga).

```bash
kubectl set image deploy nginx-deployment nginx=nginx:1.27 -n glipops   # imperativo, só para testar
kubectl rollout status deploy nginx-deployment -n glipops
kubectl get rs -n glipops -w                                            # ver o ReplicaSet novo subir e o antigo descer
```

> **Obs.:** `nginx:1.15.0` é de 2018. Para treinar o rolling update está ótimo (dá para atualizar para uma versão nova e ver a troca), mas não é imagem para usar de verdade.

## Para revisar

- [ ] Trocar a imagem no YAML de `nginx:1.15.0` para `nginx:1.27`, aplicar e acompanhar o rolling update com `kubectl get rs -n glipops -w`
- [ ] Testar o `Recreate` e comparar com o RollingUpdate
- [ ] Fazer um `rollout undo` e ver o ReplicaSet antigo voltar
- [ ] Apagar um pod do Deployment e ver o ReplicaSet criar outro
