
trap {
    &$TrapHandler
}


Function Install-RolePrimaryDomainController {
    param (
        [String] $DomainName,
        [String] $SafeModePassword
    )
    begin {
        Show-InvocationInfo $MyInvocation
    }
    end {
        Show-InvocationInfo $MyInvocation -End
    }
    process {
        trap {
            &$TrapHandler
        }

        $OSVersion = [System.Environment]::OSVersion.Version
        $VersionString = $OSVersion.Major + '.' + $OSVersion.Minor

        switch ($VersionString) {
            '6.1' {
                Import-Module ServerManager

                Add-WindowsFeature -Name "DNS","ADDS-Domain-Controller","RSAT-DFS-Mgmt-Con"

                Write-Log "Creating first domain controller ..."
<#
                $DcPromoArgs = @(
                    '/unattend',
                    '/InstallDns:yes',
                    '/ParentDomainDNSName:contoso.com',
                    '/replicaOrNewDomain:domain',
                    '/newDomain:child',
                    '/newDomainDnsName:east.contoso.com',
                    '/childName:east',
                    '/DomainNetbiosName:east',
                    '/databasePath:"e:\ntds"',
                    '/logPath:"e:\ntdslogs"',
                    '/sysvolpath:"g:\sysvol"',
                    '/safeModeAdminPassword:FH#3573.cK',
                    '/forestLevel:2',
                    '/domainLevel:2',
                    '/rebootOnCompletion:yes'
                )
#>
                $DcPromoArgs = @(
                    '/unattend',
                    '/installDns:yes',
                    '/replicaOrNewDomain:domain',
                    '/newDomain:Forest',
                    "/newDomainDnsName:${DomainName}",
                    "/safeModeAdminPassword:${SafeModePassword}",
                    '/forestLevel:4',
                    '/domainLevel:4',
                    '/rebootOnCompletion:no'
                )

                Exec 'dcpromo' $DcPromoArgs
            }
            default {
                Add-WindowsFeatureWrapper `
                    -Name "DNS","AD-Domain-Services","RSAT-DFS-Mgmt-Con" `
                    -IncludeManagementTools `
                    -NotifyRestart

                Write-Log "Creating first domain controller ..."

                $SMAP = ConvertTo-SecureString -String $SafeModePassword -AsPlainText -Force

                $null = Install-ADDSForest `
                    -DomainName $DomainName `
                    -SafeModeAdministratorPassword $SMAP `
                    -DomainMode Default `
                    -ForestMode Default `
                    -NoRebootOnCompletion `
                    -Force
            }
        }

        Write-Log "Waiting 60 seconds for reboot ..."
        Start-Sleep -Seconds 60
    }
}
