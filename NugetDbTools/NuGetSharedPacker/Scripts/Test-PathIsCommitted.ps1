function Test-PathIsCommitted {
	Test-PathIsInGitRepo -and (iex git status --porcelain)
}