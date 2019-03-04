function Get-AzureDevOpsCredential {
	param(
		# DevOps user token
		[string]$Token,
		# DevOps user email
		[string]$UserEmail
	)
	@{Authorization=("Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserEmail,$Token))))")}
}

$local:BuilderPAT = '7iyaupfve4trn5t3dbhyybvx2imdy6g7lrhr43lnaz4hfcklafra'
$local:BuilderAuthorization = Get-AzureDevOpsCredential -Token $local:BuilderPAT -UserEmail 'Builder@ecentric.co.za'