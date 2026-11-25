# Spotify Visual 3.0 - inicializador fixo, sem privilegios administrativos.
# O gerenciador e a extensao se atualizam pelo repositorio abaixo.
param([ValidateSet('Install','Open','Safe')][string]$Mode='Install')
$ErrorActionPreference='Stop'
$dir=Join-Path $env:LOCALAPPDATA 'SpotifyVisual'
$base='https://raw.githubusercontent.com/23082043wtrash-ui/spotify-visual/main/'
$log=Join-Path $dir 'atualizacoes.log'
New-Item -ItemType Directory -Path $dir -Force|Out-Null
function Log($m){Add-Content -LiteralPath $log -Encoding UTF8 -Value "$(Get-Date -Format s) $m";Write-Host $m}
function Alert($m){Add-Type -AssemblyName System.Windows.Forms;[void][System.Windows.Forms.MessageBox]::Show([string]$m,'Spotify Visual','OK','Warning')}
function Shortcut($name,$action){
    $ws=New-Object -ComObject WScript.Shell
    $desk=[Environment]::GetFolderPath('DesktopDirectory')
    $l=$ws.CreateShortcut((Join-Path $desk ($name+'.lnk')))
    $l.TargetPath=Join-Path $PSHOME 'powershell.exe'
    $l.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $dir 'Bootstrap.ps1')+'" -Mode '+$action
    $l.WorkingDirectory=$dir
    $l.WindowStyle=7
    $spotify=Join-Path $env:APPDATA 'Spotify\Spotify.exe'
    if(Test-Path $spotify){$l.IconLocation=$spotify+',0'}
    $l.Save()
}
$principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Alert 'Execute com PowerShell normal, sem administrador. Somente instaladores oficiais podem solicitar elevacao.'
    exit 1
}
$mutex=New-Object System.Threading.Mutex($false,'Local\SpotifyVisual3Launcher')
$locked=$false
$changed=$false
$worker=Join-Path $dir 'Gerenciador.ps1'
$previous=Join-Path $dir 'Gerenciador-anterior.ps1'
$state=Join-Path $dir 'gerenciador-local.json'
$blocked=Join-Path $dir 'gerenciador-bloqueado.txt'
$stage=$null
try{
    try{$locked=$mutex.WaitOne(0)}catch [System.Threading.AbandonedMutexException]{$locked=$true}
    if(-not $locked){return}
    if(Get-Process Spotify -ErrorAction SilentlyContinue){
        if($Mode -ne 'Open'){throw 'Feche o Spotify completamente, inclusive na bandeja.'}
        $spotify=Join-Path $env:APPDATA 'Spotify\Spotify.exe'
        if(Test-Path $spotify){Start-Process -FilePath $spotify}
        return
    }
    if($Mode -ne 'Safe' -and ($Mode -eq 'Install' -or -not(Test-Path (Join-Path $dir 'desativar-atualizacoes.txt')))){
        try{
            [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
            $m=Invoke-RestMethod -Uri ($base+'gerenciador.json') -TimeoutSec 8 -MaximumRedirection 0
            if($m.file -cne 'Gerenciador.ps1' -or $m.version -notmatch '^\d+\.\d+\.\d+$' -or $m.sha256 -notmatch '^[0-9a-fA-F]{64}$'){throw 'Manifesto invalido.'}
            $local=if(Test-Path $state){try{[version](Get-Content $state -Raw|ConvertFrom-Json).version}catch{[version]'0.0.0'}}else{[version]'0.0.0'}
            $current=if(Test-Path $worker){(Get-FileHash $worker -Algorithm SHA256).Hash}else{''}
            $bad=if(Test-Path $blocked){(Get-Content $blocked -Raw).Trim()}else{''}
            if([version]$m.version -ge $local -and $current -ine $m.sha256 -and ($bad -ine $m.sha256 -or $Mode -eq 'Install')){
                $stage=Join-Path $dir ('gerenciador-'+[guid]::NewGuid().ToString('N')+'.ps1')
                Invoke-WebRequest -Uri ($base+'Gerenciador.ps1') -UseBasicParsing -OutFile $stage -TimeoutSec 15 -MaximumRedirection 0
                if((Get-Item $stage).Length -gt 1048576 -or (Get-FileHash $stage -Algorithm SHA256).Hash -ine $m.sha256){throw 'Integridade do gerenciador invalida.'}
                $tokens=$null;$errors=$null
                [void][System.Management.Automation.Language.Parser]::ParseFile($stage,[ref]$tokens,[ref]$errors)
                if($errors.Count){throw ('Erro de sintaxe do gerenciador: '+$errors[0].Message)}
                if(Test-Path $worker){
                    Remove-Item $previous -Force -ErrorAction SilentlyContinue
                    [IO.File]::Replace($stage,$worker,$previous)
                }else{Move-Item -LiteralPath $stage -Destination $worker}
                $changed=$true
                Log ('Gerenciador preparado: '+$m.version)
            }
        }catch{Log ('Atualizacao ignorada: '+$_.Exception.Message)}
    }
    if(-not(Test-Path $worker)){
        if($Mode -eq 'Safe'){
            $old=Join-Path $dir 'SpotifyVisual.ps1'
            if(Test-Path $old){& (Join-Path $PSHOME 'powershell.exe') -NoProfile -ExecutionPolicy Bypass -File $old -Mode Safe;exit $LASTEXITCODE}
        }
        throw 'Nenhum gerenciador disponivel. Verifique a internet e execute o instalador novamente.'
    }
    if($Mode -eq 'Install'){
        $installed=Join-Path $dir 'Bootstrap.ps1'
        if($PSCommandPath -ine $installed){Copy-Item -LiteralPath $PSCommandPath -Destination $installed -Force}
        Shortcut 'Spotify Visual' 'Open'
        Shortcut 'Spotify Visual - modo seguro' 'Safe'
    }
    & (Join-Path $PSHOME 'powershell.exe') -NoProfile -ExecutionPolicy Bypass -File $worker -Mode $Mode
    $code=$LASTEXITCODE
    if($code -ne 0){
        if($changed){
            Set-Content -LiteralPath $blocked -Value $m.sha256
            if(Test-Path $previous){
                Copy-Item -LiteralPath $previous -Destination $worker -Force
                Log 'Gerenciador anterior restaurado.'
                Alert 'A atualizacao do gerenciador falhou. A versao anterior foi restaurada; abra o atalho novamente.'
            }else{
                # Keep the initial valid source so the safe shortcut remains usable.
                Log 'Primeira execucao falhou; sem versao anterior.'
            }
        }
        exit $code
    }
    if($changed){
        @{version=[string]$m.version;sha256=$m.sha256}|ConvertTo-Json|Set-Content -LiteralPath $state -Encoding UTF8
        Remove-Item -LiteralPath $blocked -Force -ErrorAction SilentlyContinue
        Log ('Gerenciador instalado: '+$m.version)
    }
    exit 0
}catch{
    Log ('ERRO: '+$_.Exception.Message)
    Alert ($_.Exception.Message+' Log: '+$log)
    exit 1
}finally{
    if($stage){Remove-Item -LiteralPath $stage -Force -ErrorAction SilentlyContinue}
    if($locked){$mutex.ReleaseMutex()}
    $mutex.Dispose()
}
