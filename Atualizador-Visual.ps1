# Spotify Visual - Atualizador independente v4.0.0
# Runs as the current user. Does not install or update Windhawk/Spicetify.
param([ValidateSet('Install','Open','Check')][string]$Mode='Open')
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$dir=Join-Path $env:LOCALAPPDATA 'SpotifyVisual'
$installedScript=Join-Path $dir 'Atualizador-Visual.ps1'
$taskName='Spotify Visual - Atualizacao automatica'
$log=Join-Path $dir 'atualizacoes.log'
$base='https://raw.githubusercontent.com/23082043wtrash-ui/spotify-visual/'
New-Item -ItemType Directory -Path $dir -Force|Out-Null
function Log([string]$message){
    $line="$(Get-Date -Format s) [Visual 4.0.0/$Mode] $message"
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
    Write-Host $line
}
function Alert([string]$message){
    if($Mode -eq 'Check'){return}
    Add-Type -AssemblyName System.Windows.Forms
    [void][Windows.Forms.MessageBox]::Show($message,'Spotify Visual')
}
function Running { return [bool](Get-Process Spotify -ErrorAction SilentlyContinue) }
function Hash([string]$path){
    if(Test-Path -LiteralPath $path -PathType Leaf){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
    return ''
}
function Spice([string[]]$arguments){
    Log ('spicetify '+($arguments -join ' '))
    $ErrorActionPreference='Continue'
    $output=@(& $script:spice @arguments 2>&1)
    $code=$LASTEXITCODE
    foreach($line in $output){Log ($line.ToString())}
    if($code -ne 0){throw "Spicetify retornou codigo $code."}
}
function MakeShortcut([string]$name,[string]$action){
    $desktop=[Environment]::GetFolderPath('DesktopDirectory')
    $path=Join-Path $desktop ($name+'.lnk')
    $backup=Join-Path $dir ($name+'-atalho-anterior.lnk')
    if((Test-Path -LiteralPath $path)-and -not(Test-Path -LiteralPath $backup)){Copy-Item -LiteralPath $path -Destination $backup}
    $ws=New-Object -ComObject WScript.Shell
    $link=$ws.CreateShortcut($path)
    $link.TargetPath=Join-Path $PSHOME 'powershell.exe'
    $link.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$installedScript+'" -Mode '+$action
    $link.WorkingDirectory=$dir
    $link.WindowStyle=1
    $link.IconLocation=$script:spotify+',0'
    $link.Save()
}
$mutex=New-Object System.Threading.Mutex($false,'Local\SpotifyVisual4Updater')
$locked=$false
$tmpManifest=$null
$tmpExt=$null
$pending=$false
$verified=$false
$source=$null
$active=$null
$backup=$null
$activeBackup=$null
$spotify=Join-Path $env:APPDATA 'Spotify\Spotify.exe'
try{
    $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Execute no PowerShell normal, sem administrador.'}
    try{$locked=$mutex.WaitOne(0)}catch [System.Threading.AbandonedMutexException]{$locked=$true}
    if(-not $locked){if($Mode -ne 'Check'){Alert 'Ja existe uma verificacao em andamento. Abra o atalho novamente.'};return}
    if(Running){
        if($Mode -eq 'Check'){return}
        if($Mode -eq 'Open'){Log 'Spotify ja aberto; verificacao adiada.';Start-Process -FilePath $spotify;return}
        throw 'Feche Spotify completamente antes de instalar o atualizador.'
    }
    Log 'Inicio da verificacao.'
    if(Test-Path -LiteralPath (Join-Path $dir 'desativar-atualizacoes.txt')){
        throw 'Atualizacoes pausadas pelo arquivo desativar-atualizacoes.txt. Remova-o somente se quiser reativar.'
    }
    $cmd=Get-Command spicetify.exe -ErrorAction SilentlyContinue
    if($cmd){$spice=$cmd.Source}else{$spice=Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'}
    if(-not(Test-Path -LiteralPath $spice -PathType Leaf)){throw 'Spicetify nao encontrado. Nenhuma dependencia foi alterada.'}
    $cfg=Join-Path $env:APPDATA 'spicetify\config-xpui.ini'
    foreach($line in @(& $spice -c 2>$null)){
        $p=([string]$line).Trim()
        if(Test-Path -LiteralPath $p -PathType Leaf){$cfg=$p;break}
    }
    if(-not(Test-Path -LiteralPath $cfg -PathType Leaf)){throw 'Configuracao do Spicetify nao encontrada.'}
    $ini=Get-Content -LiteralPath $cfg -Raw
    $match=[regex]::Match($ini,'(?m)^\s*spotify_path[ \t]*=[ \t]*([^\r\n]+)')
    if($match.Success){
        $candidate=Join-Path ($match.Groups[1].Value.Trim().Trim('"')) 'Spotify.exe'
        if(Test-Path -LiteralPath $candidate -PathType Leaf){$spotify=$candidate}
    }
    if(-not(Test-Path -LiteralPath $spotify -PathType Leaf)){throw 'Spotify desktop nao encontrado.'}
    $source=Join-Path (Split-Path -Parent $cfg) 'Extensions\spotify-visual.js'
    $active=Join-Path (Split-Path -Parent $spotify) 'Apps\xpui\extensions\spotify-visual.js'
    # This repair only supports a working, already registered extension. Never
    # automatically restore or re-patch an unknown new Spotify installation.
    if($ini -notmatch '(?mi)^\s*extensions[ \t]*=[^\r\n]*spotify-visual\.js'){throw 'Extensao nao registrada. Verifique o Spicetify antes de atualizar.'}
    if(-not(Test-Path -LiteralPath $active -PathType Leaf)){throw 'Estrutura ativa do Spotify mudou. Atualizacao pausada para evitar danos.'}
    if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'Copia fonte da extensao ausente. Atualizacao pausada.'}
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $tmpManifest=Join-Path $dir ('manifest-'+[guid]::NewGuid().ToString('N')+'.json')
    Invoke-WebRequest -UseBasicParsing -Uri ($base+'main/update.json?check='+[guid]::NewGuid().ToString('N')) -Headers @{'Cache-Control'='no-cache'} -TimeoutSec 20 -OutFile $tmpManifest
    if((Get-Item -LiteralPath $tmpManifest).Length -gt 16384){throw 'Manifesto maior que o limite.'}
    $m=Get-Content -LiteralPath $tmpManifest -Raw -Encoding UTF8|ConvertFrom-Json
    if($m.file -cne 'spotify-visual.js' -or $m.version -notmatch '^\d+\.\d+\.\d+$' -or $m.commit -notmatch '^[a-f0-9]{40}$' -or $m.sha256 -notmatch '^[a-f0-9]{64}$'){throw 'Manifesto invalido.'}
    Log ('Versao disponivel: '+$m.version)
    $state=Join-Path $dir 'visual-release.json'
    if(Test-Path -LiteralPath $state){
        $old=$null
        try{$old=(Get-Content -LiteralPath $state -Raw|ConvertFrom-Json).version}catch{}
        if($old -match '^\d+\.\d+\.\d+$' -and [version]$old -gt [version]$m.version){throw 'Servidor ofereceu versao anterior. Atualizacao pausada.'}
    }
    $srcHash=Hash $source
    $actHash=Hash $active
    Log ('SHA fonte: '+$srcHash+'; SHA ativo: '+$actHash)
    if($srcHash -ine $m.sha256 -or $actHash -ine $m.sha256){
        $tmpExt=Join-Path $dir ('ext-'+[guid]::NewGuid().ToString('N')+'.js')
        Invoke-WebRequest -UseBasicParsing -Uri ($base+$m.commit+'/spotify-visual.js') -TimeoutSec 30 -OutFile $tmpExt
        if((Get-Item -LiteralPath $tmpExt).Length -gt 1048576 -or (Hash $tmpExt) -ine $m.sha256){throw 'Integridade da extensao invalida.'}
        if(Running){throw 'Spotify foi aberto durante o download; nenhuma alteracao aplicada.'}
        $backup=Join-Path $dir 'visual-fonte-antes.js'
        $activeBackup=Join-Path $dir 'visual-ativo-antes.js'
        Copy-Item -LiteralPath $source -Destination $backup -Force
        Copy-Item -LiteralPath $active -Destination $activeBackup -Force
        $pending=$true
        Copy-Item -LiteralPath $tmpExt -Destination $source -Force
        Spice @('refresh','-e','--no-restart')
        if((Hash $source) -ine $m.sha256 -or (Hash $active) -ine $m.sha256){throw 'Refresh nao atualizou a copia ativa. Nenhum apply completo sera forcado.'}
    }
    $verified=$true
    @{version=[string]$m.version;sha256=$m.sha256}|ConvertTo-Json|Set-Content -LiteralPath $state -Encoding UTF8
    Log ('Extensao aplicada e verificada: '+$m.version)
    if($Mode -eq 'Install'){
        if($PSCommandPath -ine $installedScript){
            if(Test-Path -LiteralPath $installedScript){Copy-Item -LiteralPath $installedScript -Destination ($installedScript+'.bak') -Force}
            Copy-Item -LiteralPath $PSCommandPath -Destination $installedScript -Force
        }
        MakeShortcut 'Spotify Visual' 'Open'
        MakeShortcut 'Spotify Visual - atualizar' 'Install'
        Log 'Atalhos reparados. Atalho de modo seguro preservado.'
        try{
            $user=[Security.Principal.WindowsIdentity]::GetCurrent().Name
            $action=New-ScheduledTaskAction -Execute (Join-Path $PSHOME 'powershell.exe') -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$installedScript+'" -Mode Check')
            $trigger=New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
            $taskPrincipal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
            $taskSettings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 3)
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $taskPrincipal -Settings $taskSettings -Force|Out-Null
            $null=Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
            Log 'Tarefa automatica registrada: a cada 5 minutos, somente com Spotify fechado.'
            Alert ('Atualizado para '+$m.version+'. Atalhos reparados e tarefa automatica registrada.')
        }catch{
            Log ('Tarefa automatica nao registrada: '+$_.Exception.Message)
            Alert ('Extensao '+$m.version+' instalada e atalhos reparados. Nao foi possivel registrar verificacao periodica: '+$_.Exception.Message)
        }
    }
    if($Mode -ne 'Check'){Start-Process -FilePath $spotify}
}catch{
    Log ('ERRO: '+$_.Exception.Message+' (linha '+$_.InvocationInfo.ScriptLineNumber+')')
    if($pending -and -not $verified){
        try{
            if(Running){throw 'Spotify aberto; backups preservados para recuperacao manual.'}
            Copy-Item -LiteralPath $backup -Destination $source -Force
            Copy-Item -LiteralPath $activeBackup -Destination $active -Force
            if((Hash $source) -ine (Hash $backup) -or (Hash $active) -ine (Hash $activeBackup)){throw 'Hashes da recuperacao divergentes.'}
            Log 'Copias anteriores restauradas.'
        }catch{Log ('ERRO DE RECUPERACAO: '+$_.Exception.Message)}
    }
    Alert ('Atualizacao nao concluida: '+$_.Exception.Message+' Log: '+$log)
    if($Mode -ne 'Check'){exit 1}
}finally{
    if($tmpManifest){Remove-Item -LiteralPath $tmpManifest -Force -ErrorAction SilentlyContinue}
    if($tmpExt){Remove-Item -LiteralPath $tmpExt -Force -ErrorAction SilentlyContinue}
    if($locked){$mutex.ReleaseMutex()}
    $mutex.Dispose()
}
