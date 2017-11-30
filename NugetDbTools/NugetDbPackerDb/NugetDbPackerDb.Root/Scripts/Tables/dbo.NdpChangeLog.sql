CREATE TABLE [dbo].[NdpChangeLog]
(
	[ndpChangeLogID] INT NOT NULL IDENTITY(1,1), 
    [ndpChangeProject] VARCHAR(50) NOT NULL, 
    [ndpChangeLog] VARCHAR(50) NOT NULL, 
    [ndpChangeDate] DATETIME NOT NULL DEFAULT (GETDATE()),
	CONSTRAINT [PK_NdpChangeLog] PRIMARY KEY ([ndpChangeLogID]),
	CONSTRAINT [UQ_NdpChangeLog_NdpChangeProject_NdpChangeLog] UNIQUE ([ndpChangeProject], [ndpChangeLog])
)
