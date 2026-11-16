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

## Para revisar

- [ ] Trocar a imagem no YAML (ex.: `nginx:1.27`), aplicar e acompanhar o rolling update com `kubectl get rs -w`
- [ ] Fazer um `rollout undo` e ver o ReplicaSet antigo voltar
- [ ] Apagar um pod do Deployment e ver o ReplicaSet criar outro
