function Get-ObjectState {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('File', 'Folder')]
        [string]$ObjectType,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Added', 'Updated', 'Deleted')]
        [string]$State,

        [Parameter(Mandatory=$true)]
        [bool]$IsRestorable,

        [Parameter(Mandatory=$true)]
        [bool]$ParentExists,

        [Parameter(Mandatory=$false)]
        [bool]$ParentIsRestorable
    )

    $result = 0

    # Set Object Type bit
    if ($ObjectType -eq 'Folder') {
        $result = $result -bor 1
    }

    # Set State bits
    switch ($State) {
        'Added' { } # do nothing; already 0 for the relevant bits
        'Updated' { $result = $result -bor 2 }
        'Deleted' { $result = $result -bor 4 }
    }

    # Set Restorability bit
    if ($IsRestorable) {
        $result = $result -bor 8
    }

    # Set Parent Existence bit
    if ($ParentExists) {
        $result = $result -bor 16
        if ($ParentIsRestorable) {
            $result = $result -bor 32
        }
    }

    return $result
}
