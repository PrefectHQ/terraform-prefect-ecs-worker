# Example: ECS worker

This example uses the [AWS VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
to create the AWS resources required for a functional ECS cluster to host the Prefect worker.

## Usage

Once the Terraform plan is applied successfully, you can test it by assigning a
Deployment to the new ECS work pool. An example of the configuration for this
is available in the [example `prefect.yaml` file](./prefect.yaml).
See the [Prefect YAML](https://docs.prefect.io/v3/deploy/infrastructure-concepts/prefect-yaml)
documentation for more information.

The `build` and `push` steps defined in this file will build the [sample flow](./hello_world.py)
into a Docker image and push it to the ECR repository created by Terraform. Some portions of
this file will need to be replaced by the unique resource names created in AWS.

Run `prefect deploy hello_world.py:hello_world` and follow the prompts. Once complete, you will
see your Deployment in the UI. You can then start a run from the UI, or using the suggested
command from the CLI. The flow run will execute on your new ECS work pool.

## References

As an alternative to `prefect.yaml`, deployments can be managed by Terraform using the Prefect provider's
[`deployment` resource](https://registry.terraform.io/providers/PrefectHQ/prefect/latest/docs/resources/deployment).
