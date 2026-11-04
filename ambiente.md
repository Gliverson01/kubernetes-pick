# Ambiente

Cluster kind `glicluster` rodando no Ubuntu (WSL2) do PC. Comandos executados de dentro de `~/kubernetes-pick`.

Os comandos de ligar e desligar usam o filtro `label=io.x-k8s.kind.cluster`, que pega os containers de **qualquer** cluster kind, então funcionam mesmo se o cluster for recriado com outro nome.

## Ligar (quando for estudar)

```bash
docker start $(docker ps -aq --filter label=io.x-k8s.kind.cluster)
kubectl get nodes
```

O API Server leva uns 10-20 segundos para responder depois do `docker start`. Se o `kubectl` não retornar nada ou der erro de conexão, espere um pouco e rode de novo.

## Desligar (ao terminar)

```bash
docker stop $(docker ps -q --filter label=io.x-k8s.kind.cluster)
```

E no PowerShell, para o WSL parar de consumir memória:

```powershell
wsl --shutdown
```

## Criar o cluster do zero

```bash
kind create cluster --name glicluster --config labs/kind/cluster-3-nodes.yaml
docker update --restart=no $(docker ps -aq --filter label=io.x-k8s.kind.cluster)
kubectl get nodes
```

O `docker update` impede o cluster de ligar sozinho quando o WSL abre. Por padrão, o kind cria os containers com `restart=on-failure:1`, que religa o cluster se o Docker reiniciar com ele rodando (por exemplo, quando o WSL desliga sem um `docker stop` antes).

## Apagar e recriar (quando algo der muito errado)

```bash
kind delete cluster --name glicluster
kind create cluster --name glicluster --config labs/kind/cluster-3-nodes.yaml
docker update --restart=no $(docker ps -aq --filter label=io.x-k8s.kind.cluster)
```

Nada se perde: os manifests ficam salvos no Git.

## Comandos úteis

```bash
kind get clusters                  # lista os clusters
kubectl config current-context     # deve mostrar kind-glicluster
docker ps                          # os nodes do kind aparecem como containers
```

## Problemas

**`docker` não responde no WSL:** feche e reabra o terminal do Ubuntu. Se continuar, no PowerShell rode `wsl --shutdown` e abra o Ubuntu de novo.

**`git push` pede senha ou dá erro 403:** o push usa o token da conta **Gliverson01** do `gh` do Windows. No PowerShell, confira se ela continua logada:

```powershell
gh auth status
```

Se não estiver, rode `gh auth login` e entre com a conta Gliverson01.

**WSL/Docker parou de funcionar depois de mexer na BIOS ou atualizar o Windows:** no PowerShell, confira se o hypervisor está carregando:

```powershell
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent
```

Se der `False`, rode no PowerShell **como Administrador**, e depois reinicie:

```powershell
bcdedit /set "{current}" hypervisorlaunchtype auto
```

Se ainda der `False`, a opção **NX Mode** na BIOS (Advanced > CPU Configuration) precisa estar **Enabled**, junto com **SVM Mode**.
