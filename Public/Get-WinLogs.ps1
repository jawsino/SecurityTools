function Get-WinLogs {
    <# =========================================================================
    .SYNOPSIS
        Get Windows Event Viewer logs
    .DESCRIPTION
        This script will query the Windows Event Viewer and provide log details
        based on the criteria provided.
    .PARAMETER List
        List available events
    .PARAMETER Id
        Id of event in EventTable
    .PARAMETER ComputerName
        Hostname of remote system from which to pull logs.
    .PARAMETER Results
        Number of results to return.
    .PARAMETER StartTime
        Start time for event serach
    .PARAMETER EndTime
        End time for event serach
    .PARAMETER Data
        String to search for in event data
    .INPUTS
        None.
    .OUTPUTS
        System.Object.
    .EXAMPLE
        PS C:\> Get-WinLogs.ps1 -Id 8 -ComputerName $Server -Results 10
        Display last 10 RDP Sessions
    .NOTES
        Name:     Get-WinLogs
        Author:   Justin Johns
        Version:  0.1.0 | Last Edit: 2022-07-16
        - 0.1.0 - Initial version
        - 0.1.1 - Added StartTime, EndTime, and Data parameters
        - 0.1.2 - Updated EventTable variable and supporting code
        Comments: <Comment(s)>
        General notes
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent
    ========================================================================= #>
    [CmdletBinding(DefaultParameterSetName = '__lst')]
    Param(
        [Parameter(Mandatory, HelpMessage = 'List available events', ParameterSetName = '__lst')]
        [System.Management.Automation.SwitchParameter] $List,

        [Parameter(Mandatory, HelpMessage = 'Event Table Id', ParameterSetName = '__evt')]
        [ValidateScript({ $_ -GT 0 -AND $_ -LE $EventTable.Count })]
        [System.Int32] $Id,

        [Parameter(HelpMessage = 'Hostname of target computer', ParameterSetName = '__evt')]
        [ValidateScript({ Test-Connection -ComputerName $_ -Count 1 -Quiet })]
        [Alias('CN')]
        [System.String] $ComputerName,

        [Parameter(HelpMessage = 'Number of results to return', ParameterSetName = '__evt')]
        [ValidateNotNullOrEmpty()]
        [System.Int32] $Results = 10,

        [Parameter(HelpMessage = 'Start time for event serach', ParameterSetName = '__evt')]
        [ValidateNotNullOrEmpty()]
        [System.DateTime] $StartTime,

        [Parameter(HelpMessage = 'End time for event search', ParameterSetName = '__evt')]
        [ValidateNotNullOrEmpty()]
        [System.DateTime] $EndTime,

        [Parameter(HelpMessage = 'String to search for in event data', ParameterSetName = '__evt')]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Data
    )
    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        # CREATE EVENT LIST
        $eventList = for ($i = 1; $i -LT $EventTable.Count; $i++) {
            [PSCustomObject] @{
                Id          = $i
                Name        = $EventTable[$i].Name
                EventId     = $EventTable[$i].EventId
                Log         = $EventTable[$i].Log
                Description = $EventTable[$i].Description
            }
        }
    }
    Process {
        # LIST OR GET EVENTS
        switch ($PSCmdlet.ParameterSetName) {
            '__lst' {
                # OUTPUT EVENT LIST
                $eventList | Format-Table -AutoSize
            }
            '__evt' {
                # SET EVENT PARAMETERS HASHTABLE
                $eventParams = @{ }

                # CHECK FOR PARAMETERS AND ADD AS APPROPRIATE
                if ( $PSBoundParameters.ContainsKey('Results') ) { $eventParams['MaxEvents'] = $Results }
                if ( $PSBoundParameters.ContainsKey('ComputerName') ) { $eventParams['ComputerName'] = $ComputerName }

                <# $filterHash = @{
                    ProviderName = $e.Log
                    ID           = $e.EventId
                    LogName      = <String[]>
                    #Path         = <String[]>
                    #Keywords     = <Long[]>
                    #Level        = <Int32[]>
                    #StartTime    = <DateTime>
                    #EndTime      = <DataTime>
                    #UserID       = <SID>
                    #Data         = <String[]>
                    #<named-data> = <String[]>
                } #>

                # ADD EVENT ID
                $e = $EventTable[$Id] #.Where({ $_.Id -eq $Id })
                $filterHash = @{ ID = $e.EventId }

                # ADD LOG NAME OR PROVIDER
                $logNames = @('Application', 'Security', 'Setup', 'System')
                if ( $e.Log -in $logNames ) { $filterHash['LogName'] = $e.Log }
                else { $filterHash['ProviderName'] = $e.Log }

                # ADD START AND END TIMES
                if ($PSBoundParameters.ContainsKey('StartTime')) { $filterHash['StartTime'] = $StartTime }
                if ($PSBoundParameters.ContainsKey('EndTime')) { $filterHash['EndTime'] = $EndTime }

                # ADD SEARCH STRING FOR EVENT DATA SEARCH
                if ($PSBoundParameters.ContainsKey('Data')) { $filterHash['Data'] = $Data }

                # GET EVENTS
                Get-WinEvent @eventParams -FilterHashtable $filterHash
            }
        }
    }
}