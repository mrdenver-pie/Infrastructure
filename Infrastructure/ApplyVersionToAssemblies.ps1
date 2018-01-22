##-----------------------------------------------------------------------
##-----------------------------------------------------------------------
## <copyright file="ApplyVersionToAssemblies.ps1">(c) Microsoft Corporation. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
##-----------------------------------------------------------------------
##-----------------------------------------------------------------------

# 
##
# Modified by Juan Otero
##
# Implement a Build Number Format that follows Semantic Versioning while being compatible with NuGet Versioning
# Add the following variables to the Build Server definition.  The will be used as follow. 
#	Name				Read	Write
#	BuildMajorVersion	X
#	BuildMijorVersion	X
#	BuildPatchVersion	X
#	ProductSemVer				x
#	NugetSemVer					x
#	PreReleaseTag		x
##

# Look for a 0.0.0-00000.00 pattern in the build number. 
# If found use it to version the assemblies.
#
# For example, if the 'Build number format' build process parameter 
##
## $(BuildDefinitionName)_$(BuildMajorVersion).$(BuildMinorVersion).$(BuildPatchVersion)-$(Year:yy)$(DayOfYear)$(Rev:.rr)
##
# then your build numbers come out like this:
# "Build HelloWorld_3.0.0-17156.01"
# This script would then apply version to your assemblies.
#	Assembly:	3.0.0 
#	File:		3.0.17156.01 
#	NuGet:		SemVer 1 Compliant 3.0.0.1715601   - SemVer2 compliant 3.0.0-1715601


# Enable -Verbose option
[CmdletBinding()]

# Regular expression pattern to find the version in the build number 
# and then apply it to the assemblies
$SemanticVersionRegex = "\d+\.\d+\.\d+"
$MajorMinorVersionRegex = "^\d+.\d+"
$BuildRevisionVersionRegex = "\d+.\d+$"
$BuildVersionRegex = "^\d+"
$RevisionVersionRegex = "\d+$"

# These are for debugging only
#$Env:BUILD_SOURCESDIRECTORY = "C:\Users\Qeuc32\Documents\Projects\UIIntegratedCollection\IssExternal\SmartPay\CDLE.SmartPay\CDLE.SmartPay.Web\"
#$Env:BUILD_BUILDNUMBER = "Build HelloWorld_1.02.13-1765492"


# If this script is not running on a build server, remind user to 
# set environment variables so that this script can be debugged
if(-not ($Env:BUILD_SOURCESDIRECTORY -and $Env:BUILD_BUILDNUMBER))
{
	Write-Error "You must set the following environment variables"
	Write-Error "to test this script interactively."
	Write-Host '$Env:BUILD_SOURCESDIRECTORY - For example, enter something like:'
	Write-Host '$Env:BUILD_SOURCESDIRECTORY = "C:\code\FabrikamTFVC\HelloWorld"'
	Write-Host '$Env:BUILD_BUILDNUMBER - For example, enter something like:'
	Write-Host '$Env:BUILD_BUILDNUMBER = "Build HelloWorld_00.00.00-000"'
	exit 1
}

# Make sure path to source code directory is available
if (-not $Env:BUILD_SOURCESDIRECTORY)
{
	Write-Error ("BUILD_SOURCESDIRECTORY environment variable is missing.")
	exit 1
}
elseif (-not (Test-Path $Env:BUILD_SOURCESDIRECTORY))
{
	Write-Error "BUILD_SOURCESDIRECTORY does not exist: $Env:BUILD_SOURCESDIRECTORY"
	exit 1
}
Write-Verbose "BUILD_SOURCESDIRECTORY: $Env:BUILD_SOURCESDIRECTORY"

# Make sure there is a build number
if (-not $Env:BUILD_BUILDNUMBER)
{
	Write-Error ("BUILD_BUILDNUMBER environment variable is missing.")
	exit 1
}
Write-Verbose "BUILD_BUILDNUMBER: $Env:BUILD_BUILDNUMBER"

# Get and validate the version data
$SemanticVersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$SemanticVersionRegex)
$MajorMinorVersionData = [regex]::matches($SemanticVersionData,$MajorMinorVersionRegex)
$BuildRevisionVersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$BuildRevisionVersionRegex)
$BuildVersionData = [regex]::matches($BuildRevisionVersionData,$BuildVersionRegex)
$RevisionVersionData = [regex]::matches($BuildRevisionVersionData,$RevisionVersionRegex)

switch($SemanticVersionData.Count)
{
   0        
	  { 
		 Write-Error "Could not find version number data in BUILD_BUILDNUMBER."
		 exit 1
	  }
   1 {}
   default 
	  { 
		 Write-Warning "Found more than instance of version data in BUILD_BUILDNUMBER." 
		 Write-Warning "Will assume first instance is version."
	  }
}


# Transforming Assembly versions
$ProductSemanticVersion = $SemanticVersionData[0]
$ProductFileVersion = "$MajorMinorVersionData.$BuildRevisionVersionData"
$ProductNuGetVersion = "$ProductSemanticVersion.$BuildVersionData$RevisionVersionData"

#Check the pre Release Tag for NuGet versioning
if($Env:PreReleaseTag)
{
	#Set version with pre-release tags
	$ProductNuGetVersion = "$ProductSemanticVersion.$BuildVersionData$RevisionVersionData"
}
else
{
	#Set version without
	$ProductNuGetVersion = "$ProductSemanticVersion"
}


# Transformed versions
$assemblyVersion = $ProductSemanticVersion 
$assemblyFileVersion = $ProductFileVersion
$assemblyInformationalVersion = $ProductSemanticVersion 
$nuGetVersion = "$ProductNuGetVersion"
$BuildNumber = $Env:BUILD_BUILDNUMBER
$BuildConfiguration = $Env:BUILD_BUILDCONFIGURATION

# Set variable values which are made available to other steps in the build process
Write-Output ("##vso[task.setvariable variable=ProductSemVer;]$assemblyVersion")
Write-Output ("##vso[task.setvariable variable=NuGetSemVer;]$nuGetVersion")

#$Env:ProductSemVer = "$assemblyVersion"
#$Env:NuGetSemVer = "$ProductNuGetVersion"

Write-Verbose "Updated ProductSemVer is $Env:ProductSemVer" -Verbose
Write-Verbose "Updated NuGetSemVer is $Env:NuGetSemVer" -Verbose

Write-Verbose "Transformed Assembly Version is $assemblyVersion" -Verbose
Write-Verbose "Transformed Assembly File Version is $assemblyFileVersion" -Verbose
Write-Verbose "Transformed Assembly Informational Version is $assemblyInformationalVersion" -Verbose
Write-Verbose "Transformed Nuget Version is $nuGetVersion" -Verbose

# Apply the version to the assembly property files
$files = gci $Env:BUILD_SOURCESDIRECTORY -recurse -include "*Properties*","My Project" | 
	?{ $_.PSIsContainer } | 
	foreach { gci -Path $_.FullName -Recurse -include AssemblyInfo.* }

if($files)
{
	Write-Verbose "Will apply $ProductSemanticVersion to $($files.count) files." -Verbose

		foreach ($file in $files) {
			$filecontent = Get-Content($file)

			attrib $file -r
			$filecontent |
				%{$_ -replace 'AssemblyCompany\(.*\)', "AssemblyCompany(""Zteam.Dev"")" } |
				%{$_ -replace 'AssemblyCopyright\(.*\)', "AssemblyCopyright(""Copyright © 2018"")" } |
				%{$_ -replace 'AssemblyConfiguration\(.*\)', "AssemblyConfiguration(""$BuildConfiguration"")" } |
				%{$_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyVersion(""$assemblyVersion"")" } |
				%{$_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyFileVersion(""$assemblyFileVersion"")" } |
				%{$_ -replace 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', "AssemblyInformationalVersion(""$assemblyInformationalVersion"")" } | 
			Out-File $file
			Write-Verbose "$file - version applied" -Verbose
		}
}
else
{
	Write-Verbose "no assembyInfo file(s) found." -Verbose
}