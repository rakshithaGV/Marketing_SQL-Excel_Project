# Marketing_SQL-Excel_Project
# Marketing Campaign Performance Dashboard

An end-to-end data analytics project for a real estate marketing team running paid campaigns across **Meta** and **Google** in 2024. The project covers SQL-based data extraction and cleaning, metric engineering, and an Excel dashboard designed to help campaign managers make faster, evidence-based budget decisions.


![sql]()

---

## The Business Problem

A real estate company was running 10 paid campaigns across Meta and Google, targeting cities across India. They had two data sources that were never connected:

- **Platform data** — ad delivery metrics (impressions, clicks, spend) exported from Meta Ads Manager and Google Ads
- **Lead data** — CRM records of every lead generated, including status and property budget

**The result:** Campaign managers could see how much they spent and how many clicks they got, but had no way to answer the questions that actually matter:

- Which campaigns are generating leads that actually convert — not just leads?
- Is Meta or Google giving better return on spend?
- Which cities produce the highest quality demand?
- Are we spending more in months where conversion rates are low?
- What does it cost us to get one paying customer, per campaign?

Without connecting these two datasets, every budget decision was based on incomplete information.

---

## Dataset Overview

| Table | Rows | Period | Description |
|---|---|---|---|
| `platform_data` | 10,500 | Jan–Aug 2024 | Daily ad metrics per campaign/adset/ad/location |
| `lead_data` | 10,715 | Jan–Dec 2024 | CRM lead records with status and property budget |
| `Raw_Data` (merged) | 10,386 | Jan–Aug 2024 | Joined dataset with all calculated metrics |

**Campaign structure:** 10 campaigns → 30 adsets → 90 ads across Meta and Google  
**Platforms:** Meta, Google  
**Cities tracked:** Bangalore, Mumbai, Delhi, Hyderabad, Chennai, Pune, Noida, Lucknow, Ahmedabad, Goa, Jaipur, Kolkata, and more

---

## SQL Analysis — Problems Solved

### Step 1: Data Validation Before Any Analysis

Before touching metrics, the data was interrogated for quality issues. Skipping this step is where most analysis goes wrong.

**Checks performed and why:**

| Check | Finding | Why It Matters |
|---|---|---|
| Row counts | platform_data: 10,500 / lead_data: 10,715 | Confirms full import, no silent data loss |
| Date range alignment | Platform: Jan–Aug 2024 / Leads: Jan–Dec 2024 | Misaligned ranges cause incorrect join results |
| Unique campaign structure | 10 campaigns, 30 adsets, 90 ads | Establishes expected hierarchy for validation |
| Platform consistency | Both tables: Meta and Google only | Ensures join keys are compatible |
| NULL check on key columns | Zero NULLs in impressions, clicks, spend | Prevents broken CTR/CPC calculations |
| Clicks > impressions check | No violations found | Catches tracking errors that inflate CTR |
| Duplicate lead IDs | Checked via GROUP BY HAVING COUNT > 1 | Prevents double-counting in conversion metrics |

```sql
-- NULL check that protects downstream calculations
SELECT 
    SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS null_impressions,
    SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS null_clicks,
    SUM(CASE WHEN spend IS NULL THEN 1 ELSE 0 END) AS null_spend
FROM platform_data;
```

---

### Step 2: Platform and Campaign EDA

**Problem:** Management wanted to know which platform to prioritize for next quarter.  
**Finding:** Meta and Google are nearly identical in reach and spend, but diverge on conversion quality.

| Platform | Total Spend | Total Leads | Converted Leads | Conversion Rate | CPL |
|---|---|---|---|---|---|
| Meta | ₹1.30 Cr | 1,666 | 274 | **16.45%** | ₹7,829 |
| Google | ₹1.26 Cr | 1,630 | 238 | **14.60%** | ₹7,743 |

**Takeaway for campaign managers:** Google is marginally cheaper per lead, but Meta converts 1.85 percentage points higher. If optimizing for conversions (sales), Meta justifies the higher CPL. If optimizing for lead volume on a tight budget, Google is the better choice.

---

### Step 3: Lead Funnel Analysis

**Problem:** Total lead count was being used as the primary success metric. A lead that never converts is a cost, not a win.

**Lead status breakdown (10,715 leads):**

| Status | Count | % of Total |
|---|---|---|
| Qualified | 1,816 | 16.9% |
| New | 1,807 | 16.9% |
| Converted | 1,797 | 16.8% |
| Contacted | 1,782 | 16.6% |
| Interested | 1,771 | 16.5% |
| Not Interested | 1,742 | 16.3% |

**Finding:** The distribution across all stages is almost perfectly even. A healthy funnel is wide at the top and narrow at the bottom. This even spread suggests either the CRM statuses are being assigned inconsistently, or leads are not progressing through the funnel systematically. This surfaced a CRM process problem that was invisible before the analysis.

---

### Step 4: Metric Engineering — From Raw Data to Decision Metrics

**Problem:** The raw tables had spend, clicks, and impressions — but no metrics campaign managers can act on.

**Solution:** Calculated six derived metrics using SQL, with `NULLIF` to prevent division errors:

```sql
ROUND((clicks / NULLIF(impressions, 0)) * 100, 2) AS ctr,
ROUND((spend / NULLIF(impressions, 0)) * 1000, 2) AS cpm,
ROUND(spend / NULLIF(clicks, 0), 2) AS cpc,
ROUND(spend / NULLIF(COUNT(lead_id), 0), 2) AS cost_per_lead,
ROUND(converted / NULLIF(total_leads, 0) * 100, 2) AS conversion_rate_pct,
ROUND(spend / NULLIF(converted, 0), 2) AS cost_per_conversion
```

**Why `NULLIF` matters:** Without it, any row with zero leads or zero impressions crashes the query. In a 10,500-row dataset with some zero-impression days, this protection is not optional.

---

### Step 5: Joining Two Datasets — The Critical Design Decision

**Problem:** Joining platform_data and lead_data incorrectly would inflate or deflate every metric.

**Join keys used:** `campaign_id + ad_id + date`

**Why date was included:** Without date in the join condition, one lead record matches every row for that campaign and ad across all dates — multiplying leads and spend incorrectly. Including date ensures attribution is exact.

**Why LEFT JOIN, not INNER JOIN:** INNER JOIN silently drops all platform rows where no lead was generated that day. Those rows still represent real spend. LEFT JOIN retains them with NULLs in lead columns — which is the correct behavior.

```sql
FROM platform_data p
LEFT JOIN lead_data l
  ON p.campaign_id = l.utm_campaign_id 
  AND p.ad_id = l.utm_ad_id 
  AND p.date = l.date
```

---

### Step 6: Campaign Conversion Quality Analysis

**Problem:** The highest-spending campaign is not the best-performing one.

| Campaign | Total Spend | Leads | Conversion Rate | CPL |
|---|---|---|---|---|
| Plots Ahmedabad | ₹29.15L | 407 | 14.50% | ₹7,163 |
| Budget Homes Lucknow | ₹28.63L | 351 | **19.37%** | ₹8,156 |
| Luxury Homes Mumbai 2024 | ₹24.37L | 297 | **19.19%** | ₹8,204 |
| Smart Homes Hyderabad | ₹25.13L | 356 | **9.55%** | ₹7,059 |
| Affordable Flats Pune | ₹26.72L | 336 | 12.80% | ₹7,952 |

**Key finding:** Smart Homes Hyderabad has the 4th highest spend but the worst conversion rate (9.55%) — nearly half that of Budget Homes Lucknow (19.37%). It is generating leads that do not close. Reallocating budget from Hyderabad to Lucknow or Mumbai would produce more conversions for the same spend.

---

### Step 7: Geographic Demand Analysis

**Problem:** Targeting was spread across cities without understanding where demand actually converts.

| City | Total Leads | Converted | Conversion Rate |
|---|---|---|---|
| Goa | 337 | 73 | **21.66%** |
| Delhi | 327 | 59 | **18.04%** |
| Chennai | 318 | 54 | **16.98%** |
| Hyderabad | 348 | 55 | 15.80% |
| Lucknow | 340 | 52 | 15.29% |
| Mumbai | 312 | 37 | **11.86%** |
| Ahmedabad | 334 | 40 | **11.98%** |

**Key finding:** Goa has the highest conversion rate (21.66%) despite not being the highest-volume city. Mumbai and Ahmedabad generate high lead volumes but convert poorly (under 12%). Optimizing purely for lead volume would push more spend into Mumbai — the wrong decision.

---

### Step 8: Monthly Spend vs. Conversion Trend

**Problem:** Budget was not being allocated based on when conversions actually happen.

| Month | Total Spend | Leads | Conversion Rate |
|---|---|---|---|
| Jan | ₹11.77L | 157 | 15.29% |
| Feb | ₹34.03L | 452 | 14.60% |
| Mar | ₹52.75L | 704 | 15.20% |
| Apr | ₹60.38L | 777 | 15.83% |
| May | ₹58.33L | 727 | 13.89% |
| Jun | ₹27.22L | 324 | 18.21% |
| Jul | ₹10.09L | 130 | 19.23% |
| Aug | ₹2.08L | 25 | **28.00%** |

**Key finding:** Conversion rate is highest in July and August (19–28%) when spend is at its lowest. March–May received the most budget but delivered average or below-average conversion rates. This inverse relationship suggests the peak spending months may have lower-quality audiences or creative fatigue. This finding directly challenges the existing budget calendar.

---

## Dashboard — What Campaign Managers Can Now Do

The Excel dashboard connects both data sources into a single view with five analytical sections.

### Dashboard KPI Summary

| Metric | Value |
|---|---|
| Total Spend | ₹2.57 Cr |
| Total Leads Generated | 3,296 |
| Average Cost Per Lead | ₹2,312 |
| Overall Conversion Rate | 15.67% |

### Five Dashboard Views Built

**1. Campaign Summary Pivot**  
Ranks all 10 campaigns by spend, leads, conversion rate, and CPL side by side. Campaign managers can see which campaigns are generating quality conversions vs. burning budget on leads that don't close — without running a single SQL query.

**2. Monthly Trend Pivot**  
Plots spend and conversion rate together by month. Lets managers spot when they are spending more but converting less and adjust budgets before the month ends.

**3. Platform Comparison Pivot**  
Meta vs. Google breakdown across every metric — impressions, CTR, CPL, and conversion rate. Removes guesswork from platform budget allocation decisions with a direct side-by-side comparison.

**4. City Breakdown Pivot**  
Lead volume and conversion rate by city. Separates high-volume cities from high-conversion cities, which are often different places. Managers can redirect geo-targeting based on actual conversion data, not assumptions.

**5. Ad Performance Pivot**  
Ranks individual ads within campaigns by CTR, CPL, and conversion rate. Identifies which specific creatives are driving results so underperforming ads can be paused and budget shifted to what works.

---

## Tools and Techniques Used

| Tool | Purpose |
|---|---|
| MySQL | Data validation, EDA, metric engineering, JOIN design |
| `NULLIF()` | Division-by-zero protection in all calculated metrics |
| LEFT JOIN with 3-key condition | Accurate attribution without metric inflation |
| `CASE WHEN` | Conversion flag for aggregation across GROUP BY queries |
| Subqueries | Campaign lead percentage contribution against total dataset |
| Excel Pivot Tables | 5-view dashboard with slicers for interactive filtering |
| Excel Raw_Data sheet | Single source of truth powering all pivot views |

---

## Files in This Repository

```
├── marketing.sql                        — Full SQL script (validation → EDA → metrics → merged query)
├── Marketing_Campaign_Dashboard.xlsx   — Excel dashboard with raw data and 5 pivot views
└── README.md                           — This file
```

---



---

## What This Project Demonstrates

- Connecting two misaligned data sources with a multi-key JOIN designed to prevent attribution errors
- Running structured data validation before any analysis — not after
- Building metrics that answer business questions (cost per conversion) rather than vanity metrics (total impressions)
- Identifying budget misallocation through campaign and geographic conversion analysis
- Translating SQL output into a dashboard that campaign managers can use without SQL access
- Recognizing when high spend and high performance point to different campaigns — and quantifying the gap
