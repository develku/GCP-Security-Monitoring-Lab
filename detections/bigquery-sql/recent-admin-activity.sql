-- Intro query: recent high-signal admin methods (last 24h), newest first.
-- Demonstrates the BigQuery audit-log schema: every audit field lives under
-- `protopayload_auditlog` (the BQ-export shape of Log Explorer's `protoPayload`).
--
-- Replace the project id in the FROM clause if yours differs.

SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS actor,
  protopayload_auditlog.methodName                        AS method,
  protopayload_auditlog.resourceName                      AS resource,
  protopayload_auditlog.requestMetadata.callerIp          AS caller_ip
FROM `gcp-secmon-lab-kud01.secmon_logs.cloudaudit_googleapis_com_activity`
WHERE protopayload_auditlog.methodName IN (
  'SetIamPolicy',
  'google.iam.admin.v1.CreateServiceAccount',
  'google.iam.admin.v1.CreateServiceAccountKey',
  'storage.setIamPermissions',
  'v1.compute.firewalls.insert'
)
AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
ORDER BY timestamp DESC;
