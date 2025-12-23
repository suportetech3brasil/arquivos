# 1. Definição de Variáveis (Input do Usuário)
$novoNome = Read-Host "Digite o NOME desejado para a impressora"
$printerIP = Read-Host "Digite o endereço IP da impressora"
$driverExe = "C:\Users\Tech3\Downloads\Drivers_Samsung_4070\Driver_Impressao.exe"

Write-Host "`n[1/3] Executando instalador da Samsung..." -ForegroundColor Cyan

# 2. Executa o instalador em modo silencioso
Start-Process -FilePath $driverExe -ArgumentList "/S" -Wait

# Aguarda 3 segundos para o Windows registrar os objetos de impressão
Start-Sleep -Seconds 3

# 3. Localiza a impressora padrão que o instalador criou
# Buscamos pelo padrão "Samsung M337x 387x 407x Series"
$impressoraPadrao = Get-Printer | Where-Object {$_.Name -like "*Samsung M337x 387x 407x*"} | Select-Object -First 1

if ($impressoraPadrao) {
    Write-Host "[2/3] Impressora padrão detectada. Ajustando configurações..." -ForegroundColor Yellow
    
    # Criar a porta IP correta
    $portCheck = Get-PrinterPort -Name $printerIP -ErrorAction SilentlyContinue
    if (-not $portCheck) {
        Add-PrinterPort -Name $printerIP -PrinterHostAddress $printerIP
    }

    # Vincula a impressora existente à nova porta IP
    Set-Printer -Name $impressoraPadrao.Name -PortName $printerIP
    
    # RENOMEIA a impressora para o nome que você escolheu
    Rename-Printer -Name $impressoraPadrao.Name -NewName $novoNome
    
    Write-Host "[3/3] Impressora renomeada para: $novoNome" -ForegroundColor Green
} else {
    Write-Host "AVISO: A impressora padrão não foi encontrada. Tentando criação manual..." -ForegroundColor Yellow
    
    # Caso o instalador não tenha criado a impressora, tentamos o método manual
    $driverTecnico = Get-PrinterDriver | Where-Object {$_.Name -like "*Samsung M337x 387x 407x*"} | Select-Object -First 1 -ExpandProperty Name
    
    if ($driverTecnico) {
        Add-PrinterPort -Name $printerIP -PrinterHostAddress $printerIP -ErrorAction SilentlyContinue
        Add-Printer -Name $novoNome -DriverName $driverTecnico -PortName $printerIP
        Write-Host "Impressora criada manualmente com sucesso." -ForegroundColor Green
    } else {
        Write-Host "ERRO: Driver não encontrado no sistema." -ForegroundColor Red
    }
}

# 4. Limpeza de possíveis cópias duplicadas (ex: Copiar 1)
Get-Printer | Where-Object {$_.Name -like "*Samsung M337x 387x 407x* (Copiar*"} | Remove-Printer

Write-Host "`nProcesso finalizado!" -ForegroundColor Cyan