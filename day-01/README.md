# Day 01 - Ambiente e componentes do Kubernetes

**Data:** 2026-10-29

## Ambiente

- Habilitei o WSL2 no PC (o hypervisor não carregava por causa do NX na BIOS).
- Instalei Ubuntu + Docker no WSL e criei o cluster kind `pick` (1 control-plane + 2 workers). Comandos em [ambiente.md](../ambiente.md).
- Clonei este repositório dentro do WSL (`~/kubernetes-pick`).

## K8s

Abreviação de **Kubernetes**: K + 8 letras + s. Pronuncia-se "keits".

## kubectl

- É o cliente de linha de comando. Ele não roda dentro do cluster, roda na minha máquina.
- Lê o **kubeconfig** (`~/.kube/config`), onde ficam o endereço do cluster e as credenciais (no kind, um certificado).
- Faz uma requisição **HTTPS** para o **kube-apiserver** (a API do Kubernetes) para buscar, criar ou editar recursos.

> **Complemento:** quem valida o acesso é o API Server, não o kubectl. Cada requisição passa por:
> 1. **Autenticação**: quem é você? (valida o certificado)
> 2. **Autorização**: você pode fazer isso? (RBAC)
> 3. **Admission control**: em escritas, pode ajustar ou recusar o pedido
> 4. Grava ou lê no **etcd**

```bash
kubectl config view --minify     # mostra cluster, usuário e contexto em uso
kubectl get nodes -v=6           # mostra a chamada HTTP real para a API
kubectl auth can-i delete pods   # pergunta direto à etapa de autorização
```

## Container runtime (engine)

- Responsável por rodar os containers: baixar as imagens, criar os containers e deixar cada um isolado.

> **Complemento:** no Kubernetes, o runtime cuida da parte de **container** (imagem, criar, parar). No kind o runtime é o **containerd**. A **rede** dos pods é responsabilidade do plugin de **CNI**, e os **volumes** ficam com o kubelet (e com drivers CSI). O isolamento vem de recursos do kernel Linux: **namespaces** (o que o container enxerga) e **cgroups** (quanto de CPU e memória ele pode usar).

## etcd

- É o banco de dados do cluster: guarda o estado de tudo (pods, deployments, services, secrets...).
- Banco **chave-valor**. Cada objeto é uma chave, ex.: `/registry/pods/default/web-xxxx`.
- **Só o API Server acessa o etcd.** Todos os outros componentes passam pela API.
- Em produção roda com 3 ou 5 réplicas (número ímpar), usando o algoritmo **Raft**: uma mudança só vale quando a maioria concorda.
- Backup do etcd é tarefa clássica de administração (cai na CKA).

```bash
kubectl -n kube-system exec etcd-pick-control-plane -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/pods/default --prefix --keys-only
```

## Controller manager

- Faz a **reconciliação**: garante que o estado atual do cluster seja igual ao **estado desejado**.
- Se algo sai da configuração (ex.: um pod morre), ele não "restaura": ele **age** para voltar ao desejado (cria um pod novo).
- Roda vários controllers (ReplicaSet, Deployment, Node, Job...), cada um num loop: observa → compara → age → repete.

> **Correção:** o controller manager **não consulta o etcd direto**. Ele observa a **API Server** (que por sua vez lê do etcd).

> **Idempotência x reconciliação:** idempotência é a propriedade de uma operação dar o mesmo resultado se repetida (ex.: `kubectl apply` duas vezes = `unchanged`). Reconciliação é o que o controller faz. Os controllers são idempotentes para a reconciliação ser segura.

**Teste que fiz:**

```bash
kubectl create deployment web --image=nginx --replicas=3
kubectl delete pod <nome-do-pod>              # o ReplicaSet cria outro no mesmo segundo
kubectl get events --sort-by=.lastTimestamp   # mostra o Killing e o SuccessfulCreate
```

## Scheduler (ainda preciso fixar)

- Decide **em qual node** cada pod novo vai rodar. Só isso: ele **não** sobe o pod.
- Funciona em duas etapas:
  1. **Filtragem**: descarta os nodes que não servem (sem CPU/memória suficiente, com taint, que não batem com o `nodeSelector`...).
  2. **Pontuação**: entre os que sobraram, escolhe o melhor (ex.: o menos ocupado).
- No fim, grava na API o node escolhido (campo `spec.nodeName` do pod). A partir daí, o kubelet daquele node assume.

Vi isso nos eventos do teste:

```
Normal  Scheduled  pod/web-5fc9f4bf66-9xpw4  Successfully assigned default/web-5fc9f4bf66-9xpw4 to pick-worker
```

```bash
kubectl get pods -o wide   # coluna NODE mostra onde o scheduler colocou cada pod
```

## kubelet

- É o agente do Kubernetes que roda em **cada node**.
- Gerencia os pods que foram designados para o seu node: pede ao container runtime para subir os containers, reinicia se caírem, roda os health checks (probes) e reporta o status para a API.

> **Correção:** quem direciona o pod para o node é o **scheduler**, não o controller. O kubelet observa a API, vê os pods com o `nodeName` dele e sobe esses pods.

## kube-proxy

- Roda em **cada node** e faz as requisições para um **Service** chegarem nos pods certos, distribuindo entre eles (por isso parece um load balancer).

> **Complemento:** na prática, ele não fica no meio do tráfego como um proxy tradicional. Ele **programa regras** no node (iptables ou IPVS) que redirecionam o IP do Service para os IPs dos pods.

## Fluxo de um `kubectl create deployment`

```
kubectl → API Server (autentica, autoriza, grava no etcd)
        → controller (Deployment → ReplicaSet → cria os pods)
        → scheduler (escolhe o node de cada pod)
        → kubelet do node (pede ao runtime para subir os containers)
        → kube-proxy (se houver Service, roteia o tráfego para os pods)
```

## Para revisar

- [ ] Scheduler: refazer o teste olhando a coluna NODE e os eventos `Scheduled`
- [ ] Ver a diferença entre container runtime, CNI e CSI
- [ ] RBAC (quando o curso chegar lá)
- [ ] Backup e restore do etcd
