CREATE PROCEDURE [dbo].[AddNdpChangeLog]
	@ndpChangeproject VARCHAR(50),
	@ndpChangelog VARCHAR(50),
	@ndpChangeLogId INT OUTPUT
AS
BEGIN
	SET @ndpChangeLogId = dbo.MapNdpChangeLog(@ndpChangeproject, @ndpChangelog)
	IF @ndpChangeLogId IS NULL
	BEGIN
		INSERT	dbo.NdpChangeLog (ndpChangeProject, ndpChangeLog)
		VALUES	(@ndpChangeproject, @ndpChangelog)
		
		SET @ndpChangeLogId = SCOPE_IDENTITY()
	END
END