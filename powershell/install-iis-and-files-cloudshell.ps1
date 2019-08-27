Set-AzVMCustomScriptExtension -ResourceGroupName RG1 `
    -VMName SRVAZEUW0001DEV `
    -Location westeurope `
    -FileUri https://raw.githubusercontent.com/derhoppe/az-103-scripts/master/powershell/install-iis-and-files.ps1 `
    -Run 'install-iis-and-files.ps1' `
    -Name InstallIISScriptExtension