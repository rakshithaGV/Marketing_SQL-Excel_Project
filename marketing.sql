USE project;
-- -------------------------------------------------------------------------------------------------------------------------------------------------
# CREATE THE PLATFORM_DATA TABLE
CREATE TABLE platform_data (
    date DATE,
    platform VARCHAR(20),
    location VARCHAR(50),
    campaign_id VARCHAR(20),
    campaign_name VARCHAR(150),
    adset_id VARCHAR(40),
    adset_name VARCHAR(200),
    ad_id VARCHAR(50),
    ad_name VARCHAR(250),
    impressions INT,
    clicks INT,
    spend DECIMAL(10 , 2 )
);
#CREATE THE LEAD_DATA TABLE
CREATE TABLE lead_data (
    lead_id VARCHAR(20),
    date DATE,
    project_city VARCHAR(50),
    utm_campaign_id VARCHAR(20),
    utm_campaign_name VARCHAR(150),
    utm_adset_id VARCHAR(40),
    utm_adset_name VARCHAR(200),
    utm_ad_id VARCHAR(50),
    utm_ad_name VARCHAR(250),
    platform VARCHAR(20),
    marketing_lead_source VARCHAR(30),
    marketing_lead_channel VARCHAR(30),
    lead_status VARCHAR(30),
    budget BIGINT
);

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# UNDERSTAND THE STRUCTURE OF BOTH PLATFORM AND LEAD DATA TABLES 
/* validating data quality by checking row counts, date ranges, unique campaign structures, platform consistency, NULL values, 
and logical errors like clicks exceeding impressions. This ensured the dataset was reliable before calculating metrics. */

# 1. Row count in each table
SELECT COUNT(*) AS total_rows
FROM platform_data;
-- O/p: Total rows of platform_data table is 10500
SELECT COUNT(*) AS total_rows
FROM lead_data;
-- O/p: Total rows of lead_data table is 10715
/* Checked row counts to ensure data was imported correctly and no records were missing. This validates data hygiene before analysis.*/

# 2. Earliest & latest date
SELECT MIN(date) AS earliest_date, MAX(date) AS latest_date
FROM platform_data;
-- O/p: Earliest_date and latest_date of platform_data table are 2024-01-01 and 2024-08-22
SELECT MIN(date) AS earliest_date, MAX(date) AS latest_date
FROM lead_data;
-- O/p: Earliest_date and latest_date of lead_data table are 2024-01-01 and 2024-12-31
/* Checked date range to understand the time period and ensure both datasets align for proper joining.*/ 

# 3. Unique campaigns, adsets and ads
SELECT 
    COUNT(DISTINCT campaign_id) AS unique_campaigns,
    COUNT(DISTINCT adset_id) AS unique_adsets,
    COUNT(DISTINCT ad_id) AS unique_ads
FROM platform_data;
-- O/p: Unique campaigns, adsets and ads are 10, 30 and 90.
/* Checked unique campaign hierarchy to understand the structure and scale of marketing efforts.*/

# 4. Unique platforms in each table
SELECT DISTINCT platform FROM platform_data;
SELECT DISTINCT platform FROM lead_data;
-- O/p: Unique platforms in each table are 2 which are Meta and Google.
/* Checked platform distribution to compare performance across channels like Meta and Google.*/

# 5. Possible values in lead_status
SELECT DISTINCT lead_status FROM lead_data;
-- O/p: possible values in lead_status is New, Converted, Contacted, Qualified, Intrested and Not Interested.
/* Explored lead_status to understand the funnel stages and define conversion logic.*/

# 6. Null values check
SELECT 
    SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS null_impressions,
    SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS null_clicks,
    SUM(CASE WHEN spend IS NULL THEN 1 ELSE 0 END) AS null_spend
FROM platform_data;
-- O/p: There is no Null values
/* Checked for NULLs in key metrics because they can break calculations like CTR(click to rate) and CPC(cost per click).*/

# 7. Rows where clicks > impressions
SELECT *
FROM platform_data
WHERE clicks > impressions;
-- O/p: Clicks <= impressions
/* Performed a data quality check to ensure clicks do not exceed impressions, which would indicate invalid tracking. 
if such rows exists would either remove them or flag them, since they violate logical constraints */

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# EDA - EXPLORE THE PLATFORM_DATA ANALYSIS
/* To analyze platform performance, campaign spend distribution, geographic reach, monthly spend trends, top-performing ads, 
and data anomalies like zero-impression days to understand performance patterns and identify optimization opportunities */

# 8. Total impressions, clicks, spend per platform
SELECT 
    platform,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(spend) AS total_spend
FROM platform_data
GROUP BY platform;
-- O/p: Total impressions, clicks, spend per platform for Meta: 53627133,2685553 & 12474451.44 and for Google: 53075797,2631183 & 12094505.22
/*Aggregated performance by platform to compare overall reach, engagement, and cost efficiency*/
 
# 9. Total spend per campaign + highest spender
SELECT 
    campaign_name,
    SUM(spend) AS total_spend
FROM platform_data
GROUP BY campaign_name
ORDER BY total_spend DESC;
-- O/p: Total spend per campaign and in that highest spender is Plots Ahmedabad
/* Analyzed campaign-level spend to identify which campaigns consume the highest budget */

# 10. Location with most impressions
SELECT 
    location,
    SUM(impressions) AS total_impressions
FROM platform_data
GROUP BY location
ORDER BY total_impressions DESC
LIMIT 1;
-- O/p: Most impressions location is Banglore and thier total impression is  9445083
/* Identified top-performing locations in terms of reach to understand geographic targeting effectiveness. */

# 11. Monthly spend trend
SELECT 
    MONTH(date) AS month,
    SUM(spend) AS total_spend
FROM platform_data
GROUP BY MONTH(date)
ORDER BY month;
/* Analyzed monthly spend trends to identify seasonality and budget allocation patterns. Detect peak months */

# 12. Top 5 ads by clicks
SELECT 
    ad_name,
    SUM(clicks) AS total_clicks
FROM platform_data
GROUP BY ad_name
ORDER BY total_clicks DESC
LIMIT 5;
/* Identified top-performing ads based on clicks to evaluate which creatives drive the most engagement. */

# 13. Days with zero impressions
SELECT 
    COUNT(*) AS zero_impression_days
FROM platform_data
WHERE impressions = 0;
-- if any to check exact date with zero impressions
SELECT date
FROM platform_data
WHERE impressions = 0;
/* Checked for zero-impression days to identify inactive campaigns or tracking issues. Wasted budget days or if any Campaign delivery issues*/

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# EDA - EXPLORE THE LEAD_DATA ANALYSIS
/* Analyze lead distribution across platforms, funnel status, geographic demand, channel performance, and monthly trends.
 I also validated data quality by checking duplicates to ensure accurate reporting */
 
# 14. Leads per platform
SELECT 
    platform,
    COUNT(lead_id) AS total_leads
FROM lead_data
GROUP BY platform;
/* Analyzed lead distribution by platform to understand which channel generates more demand. 
Helps decide where leads are actually coming from, not just traffic. */

# 15. Lead status distribution + converted leads
SELECT 
    lead_status,
    COUNT(*) AS total_leads
FROM lead_data
GROUP BY lead_status;
-- In this Total converted lead counts are:
SELECT 
    COUNT(*) AS converted_leads
FROM lead_data
WHERE lead_status = 'Converted';
/* Analyzed lead status distribution to understand funnel performance and count final conversions. 
It helps identify where leads are getting stuck in the funnel. */

# 16. City with most leads
SELECT 
    project_city,
    COUNT(*) AS total_leads
FROM lead_data
GROUP BY project_city
ORDER BY total_leads DESC
LIMIT 1;
/* Identified top-performing cities to understand geographic high demand cities for the product. 
we are not only focus on top city, we should also check conversion rate before deciding.*/

# 17. Top marketing lead channel
SELECT 
    marketing_lead_channel,
    COUNT(*) AS total_leads
FROM lead_data
GROUP BY marketing_lead_channel
ORDER BY total_leads DESC
LIMIT 1;
-- O/p: Top marketing lead channel is Social and total_leads is 5426
/* Evaluated lead channels to identify which source drives the highest lead volume. High volume doesn’t mean high quality — conversions matter.*/

# 18. Leads per month
SELECT 
    MONTH(date) AS month,
    COUNT(*) AS total_leads
FROM lead_data
GROUP BY MONTH(date)
ORDER BY month;
/* Analyzed monthly lead trends to identify seasonality and demand patterns.
if leads increase but conversions drop - That indicates poor lead quality or targeting issues.*/

# 19. Duplicate lead_ids
SELECT 
    lead_id,
    COUNT(*) AS count
FROM lead_data
GROUP BY lead_id
HAVING COUNT(*) > 1;
/* Checked for duplicate lead IDs to ensure data accuracy and avoid double counting. */

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# CALCULATE THE MARKETING METRICS

# 20. Adding Calculated columns like CTR, CPM and CPC to platform_data
SELECT *,
    ROUND((clicks / NULLIF(impressions, 0)) * 100, 2) AS ctr, -- CTR(Click through rate) = (click/impression)*100
    ROUND((spend / NULLIF(impressions, 0)) * 1000, 2) AS cpm, -- CPM(Cost per 1000impressions)= (spend/impressions)*100
    ROUND(spend / NULLIF(clicks, 0), 2) AS cpc				  -- CPC(Cost per click) = Spend/Clicks
FROM platform_data;
/* Calculated CTR, CPM, and CPC to evaluate ad performance.
CTR measures engagement, CPM measures cost efficiency for reach, and CPC measures cost per interaction. which are critical for optimizing ad spend 
and improving ROI. I used NULLIF to avoid division errors and ROUND for clean reporting. */

#21. Adding Calculated Columns to lead_data
/*analyze campaign contribution to total leads, evaluated conversion rates per campaign, and compared average budget between converted and
non-converted leads to understand both volume and quality.*/

-- 21.1. Percentage of total leads contributed by each campaign
SELECT 
    utm_campaign_name,
    COUNT(*) AS total_leads,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM lead_data), 2) AS lead_pct -- Used subquery to calculate % against total_leads across dataset
FROM lead_data
GROUP BY utm_campaign_name
ORDER BY lead_pct DESC;
/* Calculated the percentage contribution of each campaign to understand which campaigns generate the most share of leads.*/

-- 21.2. Percentage of leads converted per campaign
SELECT 
    utm_campaign_name,
    COUNT(*) AS total_leads,
    SUM(CASE WHEN lead_status = 'Converted' THEN 1 ELSE 0 END) AS converted_leads,
    ROUND(
        (SUM(CASE WHEN lead_status = 'Converted' THEN 1 ELSE 0 END) * 100.0) 
        / COUNT(*), 2
    ) AS conversion_pct
FROM lead_data
GROUP BY utm_campaign_name
ORDER BY conversion_pct DESC;
/* Calculated conversion percentage per campaign to evaluate lead quality and campaign effectiveness.
High conversion rate is more valuable because it reflects quality.*/

-- 21.3. Average budget (Converted vs Not Converted)
SELECT 
    CASE 
        WHEN lead_status = 'Converted' THEN 'Converted'
        ELSE 'Not Converted'
    END AS conversion_group,
    ROUND(AVG(budget), 2) AS avg_budget
FROM lead_data
GROUP BY conversion_group;
/* Compared average budget across lead statuses to understand whether higher-value customers are more likely to convert. */

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# UNDERSTAND THE JOIN KEYS 
/* Q1. What column in platform_data matches utm_campaign_id in lead_data?
 Answer: platform_data.campaign_id = lead_data.utm_campaign_id
 
Q2. What column in platform_data matches utm_ad_id in lead_data?
 Answer: platform_data.ad_id = lead_data.utm_ad_id

Q3. Should date be part of the join? Why or why not ?
 Answer: Yes, date should be included to ensure that leads are matched with the correct day’s ad performance.
		 Without date, leads could be incorrectly attributed across different days. 
		 if you don’t include date It creates duplicate joins and inflates metrics because one lead can match multiple rows.

Q4. What type of join should you use: INNER or LEFT? What happens to platform rows with no matching leads
 Answer: Use LEFT JOIN to retain all platform_data rows, even if no leads were generated. 
This ensures we don’t lose ad performance data when analyzing campaigns. INNER JOIN Drops rows with no leads.
if Platform rows are retained, and lead columns become NULL. */

-- -------------------------------------------------------------------------------------------------------------------------------------------------
# MERGED QUERY WITH ALL METRICS
/*join platform_data and lead_data using campaign_id, ad_id, and date to ensure accurate attribution.
Then aggregated performance metrics like impressions, clicks, and spend, and calculated CTR, CPM, and CPC.
Also computed lead metrics like total leads, conversion rate, CPL, and handled divide-by-zero using NULLIF.*/

SELECT p.date, p.platform, p.location,l.project_city, p.campaign_id, p.campaign_name, p.adset_id, p.adset_name, p.ad_id, p.ad_name,
	-- Aggregated metrics
    SUM(p.impressions) AS total_impressions,
    SUM(p.clicks) AS total_clicks,
    ROUND(SUM(p.spend), 2) AS total_spend,
    -- Performance metrics
    ROUND((SUM(p.clicks) / NULLIF(SUM(p.impressions), 0)) * 100, 2) AS ctr,
    ROUND((SUM(p.spend) / NULLIF(SUM(p.impressions), 0)) * 1000, 2) AS cpm,
    ROUND(SUM(p.spend) / NULLIF(SUM(p.clicks), 0), 2) AS cpc,
    -- Lead metrics
    COUNT(l.lead_id) AS total_leads,
    SUM(CASE WHEN l.lead_status = 'Converted' THEN 1 ELSE 0 END) AS converted_leads,
    -- Cost per lead
    ROUND(SUM(p.spend) / NULLIF(COUNT(l.lead_id), 0), 2) AS cost_per_lead,
    -- Lead rate (leads per click)
    ROUND((COUNT(l.lead_id) / NULLIF(SUM(p.clicks), 0)) * 100, 2) AS lead_rate_pct,
    -- Conversion rate
    ROUND((SUM(CASE WHEN l.lead_status = 'Converted' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(l.lead_id), 0))
        * 100, 2) AS conversion_rate_pct,
    -- Cost per conversion
    ROUND( SUM(p.spend) / 
			NULLIF(SUM(CASE WHEN l.lead_status = 'Converted' THEN 1 ELSE 0 END), 0),
            2) AS cost_per_conversion
FROM platform_data p
LEFT JOIN lead_data l
ON p.campaign_id = l.utm_campaign_id AND p.ad_id = l.utm_ad_id AND p.date = l.date
GROUP BY p.date, p.platform, p.location,l.project_city, p.campaign_id, p.campaign_name, p.adset_id, p.adset_name, p.ad_id, p.ad_name;
/* This dataset powers the dashboard and helps identify which campaigns are efficient in both generating leads and driving conversions. */
