# 1. Identifica automaticamente a pasta onde o script esta sendo executado
$caminhoBase = $PSScriptRoot

# Definicao dos nomes dos arquivos
$driverImp     = Join-Path $caminhoBase "Driver_M4070_Print.exe"
$driverScan    = Join-Path $caminhoBase "Driver_M4070_Scan.exe"
$easyCreator   = Join-Path $caminhoBase "EasyDocumentCreator.exe"
$easyManager   = Join-Path $caminhoBase "EasyPrinterManager.exe"

# 2. Solicita os dados ao usuario
$novoNome  = Read-Host "Digite o NOME desejado para a impressora"
$printerIP = Read-Host "Digite o endereco IP da impressora"

# Função para executar instaladores com maior robustez
function Executar-Instalador {
    param([string]$caminho, [string]$nomeExibicao)
    if (Test-Path $caminho) {
        Write-Host "-> Instalando $nomeExibicao..." -ForegroundColor Cyan
        # Usamos o Start-Process com PassThru para monitorar o processo manualmente se necessário
        $processo = Start-Process -FilePath $caminho -ArgumentList "/S" -PassThru -Wait -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } else {
        Write-Host "-> Erro: Arquivo $nomeExibicao nao encontrado em $caminho" -ForegroundColor Red
    }
}

Write-Host "`n[1/6] Iniciando Driver de Impressao..." -ForegroundColor White
Executar-Instalador $driverImp "Driver de Impressao"

# --- AJUSTE DE NOME E PORTA ---
Write-Host "[2/6] Configurando Nome e IP..." -ForegroundColor Yellow
$impressoraPadrao = Get-Printer | Where-Object {$_.Name -like "*Samsung M337x 387x 407x*"} | Select-Object -First 1

if ($impressoraPadrao) {
    if (-not (Get-PrinterPort -Name $printerIP -ErrorAction SilentlyContinue)) {
        Add-PrinterPort -Name $printerIP -PrinterHostAddress $printerIP
    }
    Set-Printer -Name $impressoraPadrao.Name -PortName $printerIP
    Rename-Printer -Name $impressoraPadrao.Name -NewName $novoNome
    Write-Host "Configuracao de IP e Nome aplicada." -ForegroundColor Green
} else {
    Write-Host "Aviso: Driver instalado mas objeto de impressora nao localizado para renomear." -ForegroundColor Red
}

# --- INSTALACAO DOS DEMAIS COMPONENTES ---
# Nota: Para o EPM e EDC, as vezes o /S precisa ser /silent ou /verysilent dependendo da versao, mas /S e o padrao Samsung.
Write-Host "[3/6] Instalando Driver de Digitalizacao..." -ForegroundColor White
Executar-Instalador $driverScan "Driver de Scan"

Write-Host "[4/6] Instalando Easy Document Creator..." -ForegroundColor White
Executar-Instalador $easyCreator "Easy Document Creator"

Write-Host "[5/6] Instalando Easy Printer Manager..." -ForegroundColor White
# Se o EPM costuma travar, tentamos disparar sem o -Wait se ele demorar demais ou garantir que o processo termine
Executar-Instalador $easyManager "Easy Printer Manager"

# --- LIMPEZA ---
Write-Host "[6/6] Verificando duplicatas e finalizando..." -ForegroundColor Yellow
Get-Printer | Where-Object {$_.Name -like "*Samsung M337x 387x 407x* (Copiar*"} | Remove-Printer

Write-Host "`n=================================================" -ForegroundColor White
Write-Host "   INSTALACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
Write-Host "   Impressora: $novoNome | IP: $printerIP"
Write-Host "=================================================" -ForegroundColor White
