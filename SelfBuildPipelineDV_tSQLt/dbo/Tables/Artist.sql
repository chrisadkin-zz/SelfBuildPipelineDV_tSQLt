CREATE TABLE [dbo].[Artist] (
    [ArtistId] INT            NOT NULL,
    [Name]     NVARCHAR (140) NULL,
    CONSTRAINT [PK_Artist] PRIMARY KEY CLUSTERED ([ArtistId] ASC)
);

