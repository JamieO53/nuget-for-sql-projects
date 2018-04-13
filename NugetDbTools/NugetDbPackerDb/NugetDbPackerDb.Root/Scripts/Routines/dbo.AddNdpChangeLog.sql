CREATE PROCEDURE [dbo].[AddNdpChangeLog]
	@ndpChangeProject VARCHAR(50),
	@ndpChangeLog VARCHAR(50),
	@ndpChangeLogId INT OUTPUT
AS
BEGIN
	SET @ndpChangeLogId = dbo.MapNdpChangeLog(@ndpChangeProject, @ndpChangeLog)
	IF @ndpChangeLogId IS NULL
	BEGIN
		INSERT	dbo.NdpChangeLog (ndpChangeProject, ndpChangeLog)
		VALUES	(@ndpChangeProject, @ndpChangeLog)
		
		SET @ndpChangeLogId = SCOPE_IDENTITY()
	END
END