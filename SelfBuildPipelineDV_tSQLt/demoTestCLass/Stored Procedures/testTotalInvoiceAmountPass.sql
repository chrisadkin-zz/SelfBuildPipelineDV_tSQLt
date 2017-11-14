
CREATE PROCEDURE [demoTestCLass].[testTotalInvoiceAmountPass]
AS
BEGIN
    DECLARE  @ActualTotal  NUMERIC(10,2)
            ,@ExpectedTotal NUMERIC(10,2) = 12345678.90;
 
    SELECT @ActualTotal = ISNULL(SUM(Total), 12345678.90) 
	FROM   [dbo].[Invoice];

    EXEC tSQLt.AssertEquals @ExpectedTotal , @ActualTotal;
END;


