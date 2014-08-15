
function Get-DnsListeningIpAddress {
    $wmiDnsServer = Get-WmiObject -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Server

    $ListenAddresses = $wmiDnsServer.ListenAddresses

    if ($ListenAddresses -eq $null) {
        $ListenAddresses = $wmiDnsServer.ServerAddresses
    }

    $ListenAddresses | Where-Object { $_ -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" }
}
