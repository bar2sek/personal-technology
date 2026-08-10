# Global Resource Naming Conventions

This document defines the enterprise naming standards for all accounts, organizational units (OUs), access groups, cloud resources, and infrastructure components across our hybrid homelab ecosystem.

---

## 🎯 The Core 3 Nodes

### Layout

All lowercase split with dashes:

```html
<platform>-<product>-[<env>]
```

- `[]` denotes optional node.
- The core 3 required nodes provide a primary key to align and aid in search for the platform resources they are linked to. For example, a GitHub repository that deploys IaC code to a single account in AWS would both have the same `<platform>-<product>-<env>`.
- Names extend out from the core 3 nodes in both directions to align with specific platforms. For example, cloud platforms would have the type of resource prepended (`vm`, `vpc`, `s3`, `r53` etc.). Access groups originating in Authentik would have `authentik`.
- Nodes will be based on a master lookup table that Terraform will use for input validation and consistency.

`<#description#>` node can be added to aid in human readability. Multiple description nodes are allowed but mind overall pattern character limits.

---

## 🔐 IDP Access Group Naming Standard for All Platforms

```html
<idp-source>-<platform>-<product>-<env>-<resource-id>-<platform-permission-set>
```

### idp-source
`authentik` indicates an Authentik native group. `awsid` indicates AWS Identity Center group.

### platform-permission-set
A matching set of roles/permissions within the platform being assigned by said group. If a custom permission set or RBAC role, match names in the platform and Authentik group.
- *Examples*: `dataengineer`, `contributor`, `read`, `admin`, `poweruser`

### Access group examples:
- `authentik-aws-homelab-prod-73t0-admin`
- `authentik-aws-mealie-prod-73t0-read`
- `awsid-aws-security-prod-73t0-admin`

---

## 🏢 Organizational Unit (OU) Pattern

```html
ou-<platform>-<product/org-category>-[<#description#>-]<env>-<root-id>
```

- Must be 1 to 128 characters long.
- `org-category` examples: `security`, `infrastructure`, `network`, `general`, `workloads`.
- Only `prod` and `nonprod` environments allowed.
- `root-id` is taken from AWS Organizations `r-****` value in the management account.

### Foundation OUs:
- `ou-aws-infrastructure-prod-73t0`
- `ou-aws-security-tooling-nonprod-73t0`

### Workload OUs:
- `ou-aws-immich-prod-73t0`
- `ou-aws-mealie-prod-73t0`

---

## ☁️ Account Pattern

```html
acct-aws-<product/category>-<env>-<root-id>
```

- Must be 3–63 characters long.
- Can include lowercase letters, digits, and hyphens.
- Must start and end with a letter or digit (no leading/trailing hyphens).
- Cannot contain two consecutive hyphens.
- `root-id` is taken from AWS Organizations `r-****` value in the management account.

### Foundation Accounts:
- `acct-aws-security-logarchive-infra-prod-73t0`
- `acct-aws-mgmt-payer-infra-prod-73t0`
- `acct-aws-security-tooling-infra-prod-73t0`
- `acct-aws-network-infra-prod-73t0`

### Workload Accounts:
- `acct-aws-homelab-prod-73t0`
- `acct-aws-immich-prod-73t0`

---

## 🛠 AWS Resource Pattern

```html
<aws-resource-abbreviation>-aws-<product>-<env>-<region-code>-<three-character-iteration>
```

- `region-code` (e.g. `use2`) and `three-character-iteration` (e.g. `001`) are mandatory.

### Resource Examples:
- `s3-aws-backups-prod-use2-001`
- `r53-aws-primary-prod-use2-001`
- `role-aws-eks-connector-prod-admin`

### Access Naming Examples:
- `group-aws-homelab-prod-developer`
- `role-aws-terraform-github-prod-admin`
- `user-aws-ryan-bartusek-prod-admin`
- `pset-aws-homelab-prod-admin`
