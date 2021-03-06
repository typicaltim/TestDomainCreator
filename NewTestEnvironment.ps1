configuration NewTestEnvironment {
    param(
        [Parameter(Mandatory)]
        [PSCredential] $defaultAdUserCred,
        [Parameter(Mandatory)]
        [PSCredential] $domainSafeModeCred
    )

    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.where( { $_.Purpose -eq 'Domain Controller' }).NodeName {

        @($ConfigurationData.NonNodeData.ADGroups).foreach( {
                xADGroup $_ {
                    Ensure    = 'Present'
                    GroupName = $_
                    DependsOn = '[xADDomain]ADDomain'
                }
            })

        @($ConfigurationData.NonNodeData.OrganizationalUnits).foreach( {
                xADOrganizationalUnit $_ {
                    Ensure    = 'Present'
                    Name      = ($_ -replace '-')
                    Path      = ('DC={0},DC={1},DC={2}' -f 
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[0],
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[1],
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[2])
                    DependsOn = '[xADDomain]ADDomain'
                }
            })

        @($ConfigurationData.NonNodeData.ADUsers).foreach( {
                xADUser "$($_.FirstName) $($_.LastName)" {
                    Ensure     = 'Present'
                    DomainName = $ConfigurationData.NonNodeData.DomainName
                    GivenName  = $_.FirstName
                    SurName    = $_.LastName
                    UserName   = ('{0}{1}' -f $_.FirstName.SubString(0, 1), $_.LastName)
                    Department = $_.Department
                    Path      = ('OU={0},DC={1},DC={2},DC={3}' -f $_.Department,
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[0],
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[1],
                        ($ConfigurationData.NonNodeData.DomainName -split '\.')[2])
                    JobTitle   = $_.Title
                    Password   = $defaultAdUserCred
                    DependsOn  = '[xADDomain]ADDomain'
                }
            })

        ($Node.WindowsFeatures).foreach( {
                WindowsFeature $_ {
                    Ensure = 'Present'
                    Name   = $_
                }
            })        
        
        xADDomain ADDomain {             
            DomainName                    = $ConfigurationData.NonNodeData.DomainName
            DomainAdministratorCredential = $domainSafeModeCred
            SafemodeAdministratorPassword = $domainSafeModeCred
            DependsOn                     = '[WindowsFeature]AD-Domain-Services'
        }
    }         
}

NewTestEnvironment -OutputPath $env:USERPROFILE\DSC -ConfigurationData .\ConfigurationData.psd1