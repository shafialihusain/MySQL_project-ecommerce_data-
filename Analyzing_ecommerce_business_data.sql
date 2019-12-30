/* ANALYZING DATA OF AN E-COMMERCE BUSINESS ON VARIOUS ASPECTS LIKE:
1) Traffic sources 
2) Website performance 
3) Channel portfolio management
4) Business patterns and seasonality 
5) Product Analysis 
6) User Analysis
*/

-- 1) MONTHLY TREND FOR GSEARCH AND ORDERS FOR FIRST 8 MONTHS

SELECT YEAR(website_sessions.created_at) AS Year,
       MONTH(website_sessions.created_at) AS 'Month',
       COUNT(website_sessions.website_session_id) AS sessions,
       COUNT(orders.order_id) AS 'Orders',
       COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS 'conv_rate'
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2012-11-27' AND website_sessions.utm_source='gsearch'
GROUP BY 1,2;


-- 2) MONTHLY TREND OF ORDERS FOR GSEARCH, NONBRAND AND BRAND
       
SELECT YEAR(website_sessions.created_at) AS 'Year',
	   MONTH(website_sessions.created_at) AS 'Month', 
       COUNT(CASE WHEN website_sessions.utm_campaign='nonbrand' THEN 'nonbrand_sessions' END) AS nonbrand_sessions,
       COUNT(CASE WHEN website_sessions.utm_campaign='brand' THEN 'brand_sessions' END) AS brand_sessions,
       COUNT(website_sessions.website_session_id) AS 'Total sessions',
	   COUNT(CASE WHEN website_sessions.utm_campaign='nonbrand' AND orders.order_id IS NOT NULL THEN 'nonbrand_orders' END) AS nonbrand_orders,
       COUNT(CASE WHEN website_sessions.utm_campaign='brand' AND orders.order_id IS NOT NULL THEN 'brand_orders' END) AS brand_orders,
	   COUNT(orders.order_id) AS 'Total Orders'
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2012-11-27' AND website_sessions.utm_source = 'gsearch'
GROUP BY MONTH(website_sessions.created_at);


-- 3) MONTHLY SESSIONS AND ORDERS SPLIT BY DEVICE TYPE

SELECT YEAR(created_at) AS 'Year',
       MONTH(created_at) AS 'Month',
       COUNT(mobile_sessions) AS 'Sessions_from_mobile',
       COUNT(mobile_orders) AS 'Ordesrs_from_mobile',
       COUNT(desktop_sessions) AS 'Sessions_from_desktop',
       COUNT(desktop_orders) AS 'Orders_from_desktop'
FROM
(SELECT website_sessions.website_session_id,
       website_sessions.created_at,
       orders.order_id,
       CASE WHEN device_type='mobile' THEN 'mobile' END AS mobile_sessions,
       CASE WHEN device_type='desktop' THEN 'desktop' END AS desktop_sessions,
       CASE WHEN device_type='mobile' AND orders.order_id IS NOT NULL THEN 'mobile' END AS mobile_orders,
       CASE WHEN device_type='desktop' AND orders.order_id IS NOT NULL THEN 'desktop' END AS desktop_orders       
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2012-11-27' AND utm_source='gsearch' AND utm_campaign='nonbrand') AS abc
GROUP BY MONTH(created_at);


-- 4) MONTHLY TRENDS FOR GSEARCH, ALONGSIDE MONTHLY TREND FOR EACH OF OTHER CHANNELS

SELECT YEAR(created_at) AS Year,
       MONTH(created_at) AS Month,
       COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN website_session_id ELSE NULL END) AS gsearch_paid_search,
       COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN website_session_id ELSE NULL END) AS bsearch_paid_search,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic_search_sessions,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_tyoe_in_sessions       
FROM website_sessions
WHERE created_at<'2012-11-27'
GROUP BY 1,2;


-- 5) SESSIONS TO ORDERS CONVERSION RATES 

SELECT YEAR(website_sessions.created_at) AS Year,
       MONTH(website_sessions.created_at) AS Month,
       COUNT(website_sessions.website_session_id) AS sessions,
       COUNT(orders.order_id) AS orders,
       COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS sessions_to_order_rt
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2012-11-27'
GROUP BY 1,2;


-- 6) ESTIMATE THE REVENUE EARNED FOR GSEARCH-LANDER TEST FROM JUN 19 TO JUL 28 FOR NONBRAND

SELECT MIN(website_pageview_id), website_session_id
FROM website_pageviews
WHERE pageview_url='/lander-1';


CREATE TEMPORARY TABLE first_pageview
SELECT website_sessions.website_session_id, 
       MIN(website_pageviews.website_pageview_id) AS first_pageview
FROM website_sessions
INNER JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id>= 23504 
	  AND website_sessions.created_at< '2012-07-28'
      AND website_sessions.utm_source='gsearch'
      AND website_sessions.utm_campaign='nonbrand'
GROUP BY website_sessions.website_session_id;


CREATE TEMPORARY TABLE landing_page
SELECT first_pageview.website_session_id,
       website_pageviews.pageview_url AS landing_page
FROM first_pageview
INNER JOIN website_pageviews
ON first_pageview.first_pageview = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');


CREATE TEMPORARY TABLE sessions_lp_orders
SELECT landing_page.website_session_id,
	   landing_page,
       orders.order_id
FROM landing_page 
LEFT JOIN orders
ON landing_page.website_session_id = orders.website_session_id;


SELECT landing_page,
       COUNT(website_session_id) AS sessions,
	   COUNT(order_id) AS orders,
       COUNT(order_id)/COUNT(website_session_id) AS CVR
FROM sessions_lp_orders
GROUP BY landing_page;


SELECT MAX(website_sessions.website_session_id)
FROM website_sessions
INNER JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at< '2012-11-27'
      AND website_sessions.utm_source='gsearch'
      AND website_sessions.utm_campaign='nonbrand'
      AND website_pageviews.pageview_url = '/home';
 -- max website session id= 17145
 
 
 SELECT COUNT(website_session_id) AS sessions_since_test
 FROM website_sessions
 WHERE created_at< '2012-11-27'
       AND website_session_id> 17145
       AND utm_source='gsearch'
       AND utm_campaign='nonbrand';

/*sessions since test- 22972
* 0.0087 incremental conversion = 202 incremental orders since 7/29
roughly 4 months, that is 50 extra orders per day
*/


-- 7) FULL CONVERSION FUNNEL FROM EACH LANDING PAGE TO ORDERS

CREATE TEMPORARY TABLE first_page
SELECT website_session_id,
       MIN(website_pageview_id) AS first_page
FROM
(
SELECT website_sessions.website_session_id, 
       website_pageviews.website_pageview_id,
       website_pageviews.pageview_url
FROM website_sessions
INNER JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28' AND 
      utm_source = 'gsearch' AND utm_campaign = 'nonbrand') AS ASD
GROUP BY website_pageview_id;


CREATE TEMPORARY TABLE home_lander
SELECT website_pageviews.website_session_id,
       first_page,
       website_pageviews.pageview_url AS fp_for_session,
       CASE WHEN pageview_url = '/home' THEN website_pageviews.website_session_id ELSE NULL END AS home,
       CASE WHEN pageview_url = '/lander-1' THEN website_pageviews.website_session_id ELSE NULL END AS lander
FROM first_page
INNER JOIN website_pageviews
ON first_page.first_page = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url in ('/home','/lander-1');


SELECT fp_for_session AS landing_page,
	   COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(products) AS to_products,
       COUNT(mr_fuzzy) AS to_mr_fuzzy,
       COUNT(cart) AS to_cart,
       COUNT(shipping) AS to_shipping,
       COUNT(billing) AS to_billing,
       COUNT(thankyou) AS to_thankyou
FROM(
SELECT home_lander.website_session_id,
	   website_pageviews.pageview_url,
       home_lander.fp_for_session,
       CASE WHEN website_pageviews.pageview_url='/products' THEN home_lander.website_session_id ELSE NULL END AS products,
       CASE WHEN website_pageviews.pageview_url='/the-original-mr-fuzzy' THEN home_lander.website_session_id ELSE NULL END AS mr_fuzzy,  
       CASE WHEN website_pageviews.pageview_url='/cart' THEN home_lander.website_session_id ELSE NULL END AS cart,       
       CASE WHEN website_pageviews.pageview_url='/shipping' THEN home_lander.website_session_id ELSE NULL END AS shipping,
       CASE WHEN website_pageviews.pageview_url='/billing' THEN home_lander.website_session_id ELSE NULL END AS billing,
       CASE WHEN website_pageviews.pageview_url='/thank-you-for-your-order' THEN home_lander.website_session_id ELSE NULL END AS thankyou
FROM home_lander
INNER JOIN website_pageviews
ON home_lander.website_session_id = website_pageviews.website_session_id) AS AHD
GROUP BY fp_for_session;


-- 8) QUANTIFY THE IMPACT OF BILLING TEST 'REVENUE PER BILLING PAGE SESSION'

SELECT pageview_url AS billing_session,
       COUNT(website_session_id) AS sessions,
       COUNT(order_id) AS orders,
       SUM(revenue)/COUNT(website_session_id) AS revenue_per_billing_page_seen
FROM       
(SELECT website_pageviews.website_session_id,
       website_pageviews.pageview_url,
       orders.order_id,
       orders.items_purchased,
       orders.price_usd,
       orders.items_purchased*orders.price_usd AS revenue
FROM website_pageviews
LEFT JOIN orders
ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-09-10' AND '2012-11-10' AND website_pageviews.pageview_url IN ('/billing','/billing-2')) AS asdf
GROUP BY pageview_url;

-- Lift = $31.34 - $22.83 = $8.51

SELECT COUNT(website_session_id) AS sessions
FROM website_pageviews
WHERE created_at BETWEEN '2012-10-27' AND '2012-11-27' AND pageview_url IN ('/billing','/billing-2');


-- 9) OVERALL SESSIONS AND VOLUMES TRENDED BY QUARTER

SELECT YEAR(website_sessions.created_at) AS yr,
       QUARTER(website_sessions.created_at) AS qr,
       COUNT(website_sessions.website_session_id) AS sessions,
       COUNT(orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2015-01-01'
GROUP BY 1,2;


-- 10) SESSION TO ORDER CONV_RATE, REVENUE PER ORDER, REVENUE PER SESSION

SELECT YEAR(website_sessions.created_at) AS Yr,
       QUARTER(website_sessions.created_at) AS Qr,
       COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS s2o_conv_rate,
       SUM(price_usd)/COUNT(order_id) AS revenue_per_order,
       SUM(price_usd)/COUNT(website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at< '2015-03-20'
GROUP BY 1,2;


-- 11) ORDERS FROM GSEARCH NONBRAND, BSEARCH NONBRAND, BRAND, ORGANIC SEARCH, DIRECT TYPE IN

SELECT YEAR(created_at) AS Yr,
	   QUARTER(created_at) AS Qr,
       COUNT(nonbrand_g_orders) AS nonbrand_g_orders,
       COUNT(nonbrand_b_orders) AS nonbrand_b_orders,
       COUNT(brand_orders) AS brand_orders,
       COUNT(organic_search_orders) AS organic_search_orders,
       COUNT(direct_type_in_orders) AS direct_type_in_orders
FROM(
SELECT website_sessions.website_session_id,
       orders.order_id,
       website_sessions.created_at,
       CASE WHEN utm_source = 'gsearch' AND utm_campaign= 'nonbrand' AND order_id IS NOT NULL THEN 'nonbrand_g_orders' ELSE NULL END AS nonbrand_g_orders,
       CASE WHEN utm_source = 'bsearch' AND utm_campaign= 'nonbrand' AND order_id IS NOT NULL THEN 'nonbrand_b_orders' ELSE NULL END AS nonbrand_b_orders,
       CASE WHEN utm_campaign= 'brand'AND order_id IS NOT NULL THEN 'brand_orders' ELSE NULL END AS brand_orders,
       CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL AND order_id IS NOT NULL THEN 'organic_search_orders' ELSE NULL END AS organic_search_orders,
       CASE WHEN utm_source IS NULL AND http_referer IS NULL AND order_id IS NOT NULL THEN 'direct_type_in_orders' ELSE NULL END AS direct_type_in_orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at<'2015-01-01') AS AGDFH
GROUP BY 1,2;

    
    
-- 12) SESSION TO ORDER CONV_RATE FOR ABOVE CHANNELS    
    
SELECT YEAR(created_at) AS Yr,
	   QUARTER(created_at) AS Qr,
       COUNT(nonbrand_g_orders)/COUNT(nonbrand_g_sessions) AS nonbrand_g_s2o,
       COUNT(nonbrand_b_orders)/COUNT(nonbrand_b_sessions) AS nonbrand_b_s2o,
       COUNT(brand_orders)/COUNT(brand_sessions) AS brand_s2o,
       COUNT(organic_search_orders)/COUNT(organic_search_sessions) AS organic_search_s2o,
       COUNT(direct_type_in_orders)/COUNT(direct_type_in_sessions) AS direct_type_in_s2o
FROM(
SELECT website_sessions.website_session_id,
       orders.order_id,
       website_sessions.created_at,
       CASE WHEN utm_source = 'gsearch' AND utm_campaign= 'nonbrand' AND order_id IS NOT NULL THEN 'nonbrand_g_orders' ELSE NULL END AS nonbrand_g_orders,
	   CASE WHEN utm_source = 'gsearch' AND utm_campaign= 'nonbrand' THEN 'nonbrand_g_sessions' ELSE NULL END AS nonbrand_g_sessions,

       CASE WHEN utm_source = 'bsearch' AND utm_campaign= 'nonbrand' AND order_id IS NOT NULL THEN 'nonbrand_b_orders' ELSE NULL END AS nonbrand_b_orders,
       CASE WHEN utm_source = 'bsearch' AND utm_campaign= 'nonbrand' THEN 'nonbrand_b_sessions' ELSE NULL END AS nonbrand_b_sessions,

       CASE WHEN utm_campaign= 'brand' AND order_id IS NOT NULL THEN 'brand_orders' ELSE NULL END AS brand_orders,
       CASE WHEN utm_campaign= 'brand' THEN 'brand_sessions' ELSE NULL END AS brand_sessions,

       CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL AND order_id IS NOT NULL THEN 'organic_search_orders' ELSE NULL END AS organic_search_orders,
       CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search_sessions' ELSE NULL END AS organic_search_sessions,

       CASE WHEN utm_source IS NULL AND http_referer IS NULL AND order_id IS NOT NULL THEN 'direct_type_in_orders' ELSE NULL END AS direct_type_in_orders,
       CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in_sessions' ELSE NULL END AS direct_type_in_sessions

FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at<'2015-03-20') AS AGDFHj
GROUP BY 1,2;    
    
    
    
-- 13) MONTHLY TREND OF TOTLA SALES AND TOTAL REVENUE, AND PRODUCTWISE REVENUE AND MARGIN

SELECT YEAR(created_at) AS yr,
       MONTH(created_at) AS mo,
       -- COUNT(order_id) AS total_sales,
       SUM(price_usd) AS total_revenue,
       SUM(CASE WHEN product_id= 1 THEN price_usd ELSE NULL END) AS p1_revenue,
       SUM(CASE WHEN product_id= 1 THEN (price_usd-cogs_usd) ELSE NULL END) AS p1_margin,

       SUM(CASE WHEN product_id= 2 THEN price_usd ELSE NULL END) AS p2_revenue,
       SUM(CASE WHEN product_id= 2 THEN (price_usd-cogs_usd) ELSE NULL END) AS p2_margin,

       SUM(CASE WHEN product_id= 3 THEN price_usd ELSE NULL END) AS p3_revenue,
       SUM(CASE WHEN product_id= 3 THEN (price_usd-cogs_usd) ELSE NULL END) AS p3_margin,

       SUM(CASE WHEN product_id= 4 THEN price_usd ELSE NULL END) AS p4_revenue,
       SUM(CASE WHEN product_id= 4 THEN (price_usd-cogs_usd) ELSE NULL END) AS p4_margin
FROM order_items
WHERE created_at< '2015-03-20'
GROUP BY 1,2; 



-- 14) SESSION TO /PRODUCTS, CLICKTHROUGH_RATE FROM /PRODUCTS, % ORDERS FROM /PRODUCT (MONTHLY TREND)

CREATE TEMPORARY TABLE products_sessions
SELECT website_session_id
FROM website_pageviews
WHERE created_at< '2015-03-20' AND pageview_url='/products';


CREATE TEMPORARY TABLE ABC
SELECT products_sessions.website_session_id,
       website_pageviews.pageview_url,
       website_pageviews.created_at,
       CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy' ELSE NULL END AS to_mrfuzzy,
       CASE WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebar' ELSE NULL END AS to_lovebear,
	   CASE WHEN pageview_url = '/the-birthday-sugar-panda' THEN 'panda' ELSE NULL END AS to_panda,
       CASE WHEN pageview_url = '/the-hudson-river-mini-bear' THEN 'minibear' ELSE NULL END AS to_minibear
FROM products_sessions
INNER JOIN website_pageviews
ON products_sessions.website_session_id = website_pageviews.website_session_id;


SELECT YEAR(ABC.created_at) AS yr,
       MONTH(ABC.created_at) AS mo,
       COUNT(DISTINCT ABC.website_session_id) AS sessions_to_product,
       COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT ABC.website_session_id) AS product_page_to_order,
       (COUNT(to_mrfuzzy) + COUNT(to_lovebear) + COUNT(to_panda) + COUNT(to_minibear))/COUNT(DISTINCT ABC.website_session_id) AS clickthrough_rt_from_products
FROM ABC
LEFT JOIN orders
ON ABC.website_session_id = orders.website_session_id
GROUP BY 1,2;    


-- 15) HOW WELL EACH PRODUCT CROSS SELLS FROM ONE ANOTHER

SELECT order_id,
       MIN(created_at)
FROM orders
WHERE primary_product_id = 4;

-- order_id = 25125

SELECT primary_product,
	   COUNT(order_id) AS orders_per_primary_product,
       COUNT(cross_sell_1) AS cross_sell_1,
       COUNT(cross_sell_2) AS cross_sell_2,
       COUNT(cross_sell_3) AS cross_sell_3,
       COUNT(cross_sell_4) AS cross_sell_4
FROM(
SELECT order_id,
       MAX(primary_product) AS primary_product,
       MAX(cross_sell_1) AS cross_sell_1,
       MAX(cross_sell_2) AS cross_sell_2,
       MAX(cross_sell_3) AS cross_sell_3,
       MAX(cross_sell_4) AS cross_sell_4
FROM(
SELECT order_id,
       created_at,
	   CASE WHEN is_primary_item=1 THEN product_id ELSE NULL END AS primary_product,
       CASE WHEN is_primary_item=0 AND product_id=1 THEN order_id ELSE NULL END AS cross_sell_1,
       CASE WHEN is_primary_item=0 AND product_id=2 THEN order_id ELSE NULL END AS cross_sell_2,
       CASE WHEN is_primary_item=0 AND product_id=3 THEN order_id ELSE NULL END AS cross_sell_3,
       CASE WHEN is_primary_item=0 AND product_id=4 THEN order_id ELSE NULL END AS cross_sell_4
FROM order_items
WHERE order_id>= 25125 AND created_at<'2015-03-20') AS AJFH
GROUP BY order_id) AS GHK
GROUP BY 1
ORDER BY 1;


-- 16) WHAT STEPS CAN BE TAKEN TO IMPROVE COMPANIE'S OVERALL PERFORMANCE (Theoretical).

/*
We can add additional products which can cross sell well and make better recommendations
We can improve the user experience with pages having low clickthrough rate
We can have offers during the peak seasons like november december or february
We can work on decreasing the number of refunds by improving quality even further and thus increase overall margin
We can optimize bids for channels 
We can improve the customer support experience to make loyal customers
We can understand and improve experience for valuable customers by feedback
*/