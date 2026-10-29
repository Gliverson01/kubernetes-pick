# Ambiente

Cluster kind `pick` rodando no Ubuntu (WSL2) do PC. Comandos executados de dentro de `~/kubernetes-pick`.

## Ligar o ambiente (depois de reiniciar o PC)

O cluster para quando o WSL desliga. Para voltar:

```bash
docker start pick-control-plane pick-worker pick-worker2
kubectl get nodes
```

Os nodes podem levar uns segundos para ficar `Ready`.

## Criar o cluster do zero

```bash
kind create cluster --name pick --config labs/kind/cluster-3-nodes.yaml
kubectl get nodes
```

## Apagar e recriar (quando algo der muito errado)

```bash
kind delete cluster --name pick
kind create cluster --name pick --config labs/kind/cluster-3-nodes.yaml
```

Nada se perde: os manifests ficam salvos no Git.

## Comandos úteis

```bash
kind get clusters                  # lista os clusters
kubectl config current-context     # deve mostrar kind-pick
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
