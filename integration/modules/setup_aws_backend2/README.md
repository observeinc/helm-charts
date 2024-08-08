## setup_aws_backend module

The module performs the following actions in `us-west-1` region. It's meant to be only used once as an initial setup for state management.

- Sets up an S3 bucket `helm-charts-agent-terraform-state` to store state information related to helm-charts repo 
- Create an IAM role `gh-helm-charts-repo`
- Create an IAM Policy called "terraform-backend" with below permissions allowed on bucket and ec2 related infrastructure: `helm-charts-agent-terraform-state`
   - "s3:GetObject" 
   - "s3:PutObject"
   - "s3:DeleteObject"
   - "s3:ListBucket"
   - "eks:*" for regions `us-west-1` and `us-west-2`
- Create an IAM policy for role assumption of `gh-helm-charts-repo` by certain IAM roles and root accounts 
- Attach both policies to IAM role `gh-helm-charts-repo` 

The IAM role `gh-helm-charts-repo` is meant to be used as a Github Actions Service Account for the `helm-charts` repo.


The aws provider role used to initially set up this module above must have admin access. A role assumption of type `OrganizationAccountAccessRole` can be used so the bucket and roles created are limited within an account instead of root level.
 