CREATE FUNCTION [dbo].[MapNdpChangeLog]
(
	@ndpChangeProject VARCHAR(50),
	@ndpChangelog VARCHAR(50)
)
RETURNS INT
AS
BEGIN
	DECLARE @id INT = NULL

	SELECT	@id = ndpChangeLogID
	FROM	dbo.NdpChangeLog
	WHERE	ndpChangeProject = @ndpChangeProject
		AND	ndpChangeLog = @ndpChangelog

	RETURN @id
END
