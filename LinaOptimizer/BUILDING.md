# Build (EXE)

## Pré-requisitos
- Windows PowerShell 5.1+ (ou PowerShell 7+) com permissões de Administrador quando necessário.
- Acesso à internet para instalar o módulo `ps2exe`.

## Passo a passo (servidor web)
1. Abra PowerShell na pasta do projeto.
2. Execute:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   ./build-exe.ps1 -BuildServer
   ```
3. O executável será gerado em `dist/LinaOptimizerServer.exe` junto com as pastas `web/`, `modules/`, `assets/` e `logs/`.
4. Execute o EXE dentro da pasta `dist/` para garantir que ele encontre os assets.

## Passo a passo (desktop)
1. Abra PowerShell na pasta do projeto.
2. Execute:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   ./build-exe.ps1 -BuildDesktop
   ```
3. O executável será gerado em `dist/LinaOptimizerDesktop.exe` junto com `ui.xaml` e as dependências.

## Observações
- O script `build-exe.ps1` copia os arquivos necessários para `dist/` antes de compilar.
- Se quiser usar uma porta fixa no servidor, defina a variável `LINA_PORT` antes de executar:
  ```powershell
  $env:LINA_PORT = 8787
  ./dist/LinaOptimizerServer.exe
  ```
- Para distribuição mais avançada (instalador), use ferramentas como Inno Setup ou NSIS apontando para a pasta `dist/`.
