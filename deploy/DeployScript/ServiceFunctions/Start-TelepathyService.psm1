function Start-TelepathyService {
    param (
        [string]$DestinationPath,
        [string]$DesStorageConnectionString,
        [string]$BatchAccountName,
        [string]$BatchPoolName,
        [string]$BatchAccountKey,
        [string]$BatchAccountServiceUrl,
        [switch]$EnableLogAnalytics,
        [string]$WorkspaceId,
        [string]$AuthenticationId
    )  

    Write-Log -Message "Set log source as StartTelepathyService"
    Set-LogSource -SourceName "StartTelepathyService"

    Write-Log -Message "Start open NetTCPPortSharing"
    cmd /c "sc.exe config NetTcpPortSharing start=demand"

    Write-Log -Message "Set TELEPATHY_SERVICE_WORKING_DIR environment varaibles in session machine"
    cmd /c "setx /m TELEPATHY_SERVICE_WORKING_DIR ^"C:\TelepathyServiceRegistration\^""

    Write-Log -Message "Open tcp port"
    New-NetFirewallRule -DisplayName "Open TCP port for telepathy" -Direction Inbound -LocalPort 9087, 9090, 9091, 9092, 9093 -Protocol TCP -Action Allow

    Write-Log -Message "Add EchoClient in PATH environment varaible"
    $EchoClientPath = "$DestinationPath\Echoclient"
    $env:path = $env:path + ";$EchoClientPath"
    [System.Environment]::SetEnvironmentVariable("PATH", $env:path, "Machine")

    Write-Log -Message "Script location path: $DestinationPath"
    write-Log -Message "BatchAccountName: $BatchAccountName"
    Write-Log -Message "BatchPoolName: $BatchPoolName"

    Try {
        Write-Log -Message "Start session launcher"
        $sessionLauncherExpression = @{
            DestinationPath = $DestinationPath
            DesStorageConnectionString = $DesStorageConnectionString 
            BatchAccountName = $BatchAccountName 
            BatchPoolName = $BatchPoolName
            BatchAccountKey = $BatchAccountKey
            BatchAccountServiceUrl = $BatchAccountServiceUrl
        }
        if ($EnableLogAnalytics) {
            Write-Log -Message "Enable Log Analytics in Session Launcher"
         $logConfig = @{
               EnableLogAnalytics=$true
               WorkspaceId = $WorkspaceId
               AuthenticationId = $AuthenticationId;
            }
         $sessionLauncherExpression = $sessionLauncherExpression + $logConfig
        }
        Start-SessionLauncher @sessionLauncherExpression
	
        Write-Log -Message "Start broker"
        $brokerExpression = @{
          DestinationPath = $DestinationPath
          SessionAddress = "localhost"  
        } 
        if ($EnableLogAnalytics) {
            Write-Log -Message "Enable Log Analytics in Broker"
            $logConfig = @{
               EnableLogAnalytics=$true
               WorkspaceId = $WorkspaceId
               AuthenticationId = $AuthenticationId;
            }
         $brokerExpression = $brokerExpression + $logConfig
        }
        Start-Broker @brokerExpression
    }
    Catch {
        Write-Log -Message "Fail to start telepathy service" -Level Error
        Write-Log -Message $_ -Level Error
    }
}
Export-ModuleMember -Function Start-TelepathyService
