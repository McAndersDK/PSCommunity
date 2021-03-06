function Get-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $DataCollectorSetName,

    [parameter(Mandatory = $true)]
    [System.String]
    $XmlTemplatePath
  )

  $logmanquery = (logman.exe query $DataCollectorSetName | Select-String -Pattern Name) -replace 'Name:                 ', ''

  if ($logmanquery -contains $DataCollectorSetName) 
  {
    $Ensure = $true
  }
  else 
  {
    $Ensure = $false
  }


  $returnValue = @{
    DataCollectorSetName = $DataCollectorSetName
    Ensure               = $Ensure
    XmlTemplatePath      = $XmlTemplatePath
  }

  $returnValue
}


function Set-TargetResource
{
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $DataCollectorSetName,

    [ValidateSet('Present','Absent')]
    [System.String]
    $Ensure,

    [parameter(Mandatory = $true)]
    [System.String]
    $XmlTemplatePath
  )


  if( $Ensure -eq 'Present' )
  {
    if (Test-Path -Path $XmlTemplatePath) 
    {
      Write-Verbose -Message "Importing logman Data Collector Set $DataCollectorSetName from Xml template $XmlTemplatePath"

      $null = logman.exe import -n $DataCollectorSetName -xml $XmlTemplatePath
    } else 
    {
      Write-Verbose -Message "$XmlTemplatePath not found or temporary inaccessible, trying again on next consistency check"
    }
  }
  elseif( $Ensure -eq 'Absent' ) 
  {
    Write-Verbose -Message "Removing logman Data Collector Set $DataCollectorSetName"

    $null = logman.exe delete $DataCollectorSetName
  }
}


function Test-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Boolean])]
  param
  (
    [parameter(Mandatory = $true)]
    [System.String]
    $DataCollectorSetName,

    [ValidateSet('Present','Absent')]
    [System.String]
    $Ensure,

    [parameter(Mandatory = $true)]
    [System.String]
    $XmlTemplatePath
  )


  $logmanquery = (logman.exe query $DataCollectorSetName | Select-String -Pattern Name) -replace 'Name:                 ', ''

  if ($logmanquery -contains $DataCollectorSetName) 
  {
    Write-Verbose -Message "Data Collector $DataCollectorSetName exists"

    if( $Ensure -eq 'Present' ) 
    {
      return $true
    }
    elseif ( $Ensure -eq 'Absent' ) 
    {
      return $false
    }
  }
  else 
  {
    Write-Verbose -Message "Data Collector $DataCollectorSetName does not exist"

    if( $Ensure -eq 'Present' ) 
    {
      return $false
    }
    elseif ( $Ensure -eq 'Absent' ) 
    {
      return $true
    }
  }
}


Export-ModuleMember -Function *-TargetResource