if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

Describe "Get-GroupNode" {
	Context "Exists" {
		It "Is in the module" {
			Get-Module NuGetShared | % {
				$_.ExportedFunctions['Get-GroupNode'] 
			} | should be 'Get-GroupNode'
		}
	}
	Context "Empty group exists" {
		[xml]$x = @'
<doc><group/></doc>
'@
		$parentNode = $x.doc
		$group = Get-GroupNode -ParentNode $parentNode -Id 'group'
		It "Group node type" {
			$group.GetType().Name | should be 'XmlElement'
		}
		It "Group node name" {
			$group.name | should be 'group'
		}
	}
	Context "Non-empty group exists" {
		[xml]$x = @'
<doc><group><subgroup/></group></doc>
'@
		$parentNode = $x.doc
		$group = Get-GroupNode -ParentNode $parentNode -Id 'group'
		It "Group node type" {
			$group.GetType().Name | should be 'XmlElement'
		}
		It "Group node name" {
			$group.name | should be 'group'
		}
	}
	Context "Group does not exist" {
		[xml]$x = @'
<doc></doc>
'@
		$parentNode = $x.SelectSingleNode('doc')
		$group = Get-GroupNode -ParentNode $parentNode -Id 'group'
		It "Empty group added" {
			$parentNode.SelectSingleNode('group') | should not benullorempty
		}
		It "Group node type" {
			$group.GetType().Name | should be 'XmlElement'
		}
		It "Group node name" {
			$group.name | should be 'group'
		}
	}
}