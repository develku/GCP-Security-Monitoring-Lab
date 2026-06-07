-- Detection: Persistence chain (CORRELATION)
-- MITRE: T1136.003 (create identity) -> T1098.003 (grant role) -> T1098.001 (mint key)
--
-- WHY SQL: a Log Explorer filter can only match ONE event. This attack is a
-- *sequence* of three events by the same actor in a short window. Detecting the
-- sequence requires correlating events — which is exactly what SQL (GROUP BY +
-- HAVING over a time window) does and filters cannot.
--
-- Logic: find any actor who performed all THREE chain methods within 30 minutes.
-- Replace the project id in the FROM clause if yours differs.

WITH chain_events AS (
  SELECT
    timestamp,
    protopayload_auditlog.authenticationInfo.principalEmail AS actor,
    protopayload_auditlog.methodName                        AS method
  FROM `gcp-secmon-lab-kud01.secmon_logs.cloudaudit_googleapis_com_activity`
  WHERE protopayload_auditlog.methodName IN (
    'google.iam.admin.v1.CreateServiceAccount',    -- T1136.003  identity created
    'SetIamPolicy',                                -- T1098.003  role granted
    'google.iam.admin.v1.CreateServiceAccountKey'  -- T1098.001  portable credential
  )
)
SELECT
  actor,
  MIN(timestamp)                                         AS window_start,
  MAX(timestamp)                                         AS window_end,
  TIMESTAMP_DIFF(MAX(timestamp), MIN(timestamp), MINUTE) AS span_minutes,
  COUNT(DISTINCT method)                                 AS distinct_steps,
  ARRAY_AGG(DISTINCT method)                             AS methods
FROM chain_events
GROUP BY actor
HAVING
  distinct_steps = 3          -- all three stages present for this actor
  AND span_minutes <= 30      -- and clustered within a 30-minute window
ORDER BY window_end DESC;

-- Tuning (production refinements):
--   * `SetIamPolicy` is broad — narrow it to a *primitive-role grant* by unnesting
--     protopayload_auditlog.servicedata_v1_iam.policyDelta.bindingDeltas.
--   * Enforce ORDER (create -> grant -> key) with MIN(timestamp) per method, not just
--     "all three present".
--   * Allow-list known automation actors (CI/CD service accounts).
