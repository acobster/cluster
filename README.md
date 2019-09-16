# Flynn Cluster on DigitalOcean

DigitalOcean account credentials + this repo = Flynn cluster running on DO

## Prerequisites

First, make sure you have `terraform`, `doctl`, and `ansible` installed on your system.

You'll also want to make sure you're authenticated against the DigitalOcean API by running:

```bash
doctl auth init
```

Finally, you'll need to have your default SSH key on hand. To get a list of keys that DigitalOcean knows about, run:

```bash
doctl compute ssh-key list
```

The ID is what we care about here; Terraform will prompt you for it when you deploy.

## Creating a cluster

Now, to create a cluster, just run:

```bash
./deploy
```

This will prompt you for your DigitalOcean API token and your SSH key ID, and spin up a cluster for you with those credentials.

Run `deploy -h` for usage. You can pass additional args to `terraform plan` directly on the command line via extra positional args, e.g.:

```bash
./deploy -var do_api_token=YOUR_TOKEN
```
