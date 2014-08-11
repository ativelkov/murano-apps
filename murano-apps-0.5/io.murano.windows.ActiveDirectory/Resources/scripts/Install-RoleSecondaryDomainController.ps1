
trap {
    &$TrapHandler
}


Function Install-RoleSecondaryDomainController
{
<#
.SYNOPSIS
Install additional (secondary) domain controller.

#>
    param
    (
        [String]
        # Domain name to join to.
        $DomainName,

        [String]
        # Domain user who is allowed to join computer to domain.
        $UserName,

        [String]
        # User's password.
        $Password,

        [String]
        # Domain controller recovery mode password.
        $SafeModePassword
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
        $VersionString = "$($OSVersion.Major).$($OSVersion.Minor)"

        switch($VersionString) {
            '6.1' {
                Import-Module ServerManager

                Add-WindowsFeature -Name "DNS","ADDS-Domain-Controller","RSAT-DFS-Mgmt-Con"

                Write-Log "Adding secondary domain controller ..."
<#
                $DcPromoArgs = @(
                    '/unattend',
                    '/InstallDns:yes',
                    '/confirmGC:yes',
                    '/replicaOrNewDomain:replica',
                    '/databasePath:"e:\ntds"',
                    '/logPath:"e:\ntdslogs"',
                    '/sysvolpath:"g:\sysvol"',
                    '/safeModeAdminPassword:M6$,U8Gvx4',
                    '/rebootOnCompletion:yes'
                )
#>
                $DcPromoArgs = @(
                    '/unattend',
                    '/installDns:yes',
                    '/confirmGC:yes',
                    '/replicaOrNewDomain:replica',
                    "/safeModeAdminPassword:${SafeModePassword}",
                    '/rebootOnCompletion:no'
                )

                Exec 'dcpromo' $DcPromoArgs
            }
            default {
                $Credential = New-Credential -UserName "$DomainName\$UserName" -Password $Password

                # Add required windows features
                Add-WindowsFeatureWrapper `
                    -Name "DNS","AD-Domain-Services","RSAT-DFS-Mgmt-Con" `
                    -IncludeManagementTools `
                    -NotifyRestart

                Write-Log "Adding secondary domain controller ..."

                $SMAP = ConvertTo-SecureString -String $SafeModePassword -AsPlainText -Force

                Install-ADDSDomainController `
                    -DomainName $DomainName `
                    -SafeModeAdministratorPassword $SMAP `
                    -Credential $Credential `
                    -NoRebootOnCompletion `
                    -Force `
                    -ErrorAction Stop | Out-Null
            }
        }

        Write-Log "Waiting for restart ..."
    }
}
