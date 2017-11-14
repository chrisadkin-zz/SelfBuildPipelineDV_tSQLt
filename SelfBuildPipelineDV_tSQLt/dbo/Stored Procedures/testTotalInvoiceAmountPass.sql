CREATE PROCEDURE [dbo].[testTotalInvoiceAmountPass]
AS
BEGIN
    DECLARE  @InvoiceTotal  NUMERIC(10,2)
            ,@ExpectedTotal NUMERIC(10,2) = 12345678.90;
 
    SELECT @InvoiceTotal = ISNULL(SUM(Total), 12345678.90) 
	FROM   [dbo].[Invoice];

    DECLARE @expected MONEY; SET @expected = 2.4;   --(rate * amount)
    EXEC tSQLt.AssertEquals @ExpectedTotal , @InvoiceTotal;

END;

