# Compilando o LinaOptimizer para EXE (passo a passo)

## Pré-requisitos
- Windows 10/11.
- PowerShell 5.1+ (ou PowerShell 7).
- Permissões de administrador para aplicar tweaks.

## 1) Instalar o módulo PS2EXE (empacotador)
Abra o PowerShell como Administrador e rode:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
Install-Module -Name PS2EXE -Scope CurrentUser
```

## 2) Gerar o EXE do painel principal (WPF)
Dentro da pasta do projeto, rode:

```powershell
Invoke-PS2EXE .\main.ps1 .\dist\LinaOptimizer.exe -requireAdmin -iconFile .\assets\icons\lina.ico
```

> Se não tiver ícone, remova `-iconFile` ou coloque um `.ico` válido.

## 3) Gerar o EXE do servidor local (web)
```powershell
Invoke-PS2EXE .\servidor.ps1 .\dist\LinaOptimizerServer.exe -requireAdmin -iconFile .\assets\icons\lina.ico
```

## 4) Distribuição
Inclua na mesma pasta do EXE:
- `web/` (front-end),
- `modules/` (scripts),
- `ui.xaml`,
- `assets/`.

Exemplo de estrutura:
```
dist/
  LinaOptimizer.exe
  LinaOptimizerServer.exe
  web/
  modules/
  ui.xaml
  assets/
```

## 5) Teste rápido
Execute `LinaOptimizer.exe` ou `LinaOptimizerServer.exe` e valide:
- Abertura da UI.
- Aplicação e reversão de tweaks.
- Modal de licença e validação da chave.

## Dicas
- Para criar instalador, você pode usar Inno Setup ou NSIS apontando para a pasta `dist/`.
