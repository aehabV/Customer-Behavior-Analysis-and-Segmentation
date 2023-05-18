--EXECUTE THIS CODE ONLY ONCE AT THE BEGINNING OF THE SESSION
--ALTER TABLE TABLERETAIL ADD INVOICE_DATE DATE;
--UPDATE TABLERETAIL
--SET INVOICE_DATE = TO_DATE(INVOICEDATE, 'MM/DD/YYYY HH24:MI');
--
--ALTER TABLE TABLERETAIL DROP COLUMN INVOICEDATE;
--
--GET MOST RECENT INVOICE DATE IN OUR DATA
--SELECT MAX(INVOICE_DATE) FROM TABLERETAIL;

--------------------------------------------------------------------------------------------------------------------------

--CTEs THAT CALCULATES THE RFM SCORES FOR EACH CUSTOMER
WITH CUST_RFM AS (SELECT CUSTOMER_ID, TRUNC((TO_DATE('09-DEC-11', 'DD-MON-YY') - MAX(INVOICE_DATE))) RECENCY, 
                                                 COUNT(DISTINCT INVOICE) FREQUENCY, SUM(PRICE*QUANTITY) MONETARY
                                    FROM TABLERETAIL
                                    GROUP BY CUSTOMER_ID
                                    ),

CUST_RFM_SCORES AS (SELECT CUSTOMER_ID,  RECENCY, FREQUENCY, MONETARY, NTILE(5) OVER (ORDER BY RECENCY DESC) R_SCORE, 
                                                        NTILE(5) OVER (ORDER BY FREQUENCY, MONETARY) FM_SCORE
                                          FROM CUST_RFM
                                          ORDER BY RECENCY, FREQUENCY, MONETARY
                                          )

--SEGMENTING CUSTOMERS BASED ON THEIR RFM SCORES
SELECT  CUSTOMER_ID,  RECENCY, FREQUENCY, MONETARY, R_SCORE, FM_SCORE, 
               CASE 
                    WHEN (R_SCORE, FM_SCORE) IN ((5,5), (5,4), (4,5)) THEN 'Champions' 
                    WHEN (R_SCORE, FM_SCORE) IN ((5,3), (4,4), (3,5), (3,4)) THEN 'Loyal Customers'                                                                            
                    WHEN (R_SCORE, FM_SCORE) IN ((5,2), (4,2), (3,3), (4,3)) THEN 'Potential Loyalists' 
                    WHEN (R_SCORE, FM_SCORE) IN ((4,1), (3,1)) THEN 'Promising'                                                                             
                    WHEN R_SCORE = 5 AND FM_SCORE = 1 THEN 'Recent Customers' 
                    WHEN (R_SCORE, FM_SCORE) IN ((3,2), (2,3), (2,2), (2,1)) THEN 'Customers Needing Attention' 
                    WHEN (R_SCORE, FM_SCORE) IN ((2,5), (2,4), (1,3)) THEN 'At Risk' 
                    WHEN (R_SCORE, FM_SCORE) IN ((1,5), (1,4)) THEN 'Cannot Lose Them'
                    WHEN R_SCORE = 1 AND FM_SCORE = 2 THEN 'Hibernating' 
                    WHEN R_SCORE = 1 AND FM_SCORE = 1 THEN 'Lost'                                                                              
               END AS SEGMENT
FROM CUST_RFM_SCORES
ORDER BY SEGMENT;