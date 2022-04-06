# AutoGitOps Testing Repo

![License](https://img.shields.io/badge/license-MIT-green.svg)

> We use multiple GitHub Repos, so you have to use a PAT

- Create a Personal Access Token (PAT) in your GitHub account
  - Grant repo and package access
  - You can use an existing PAT
  - <https://github.com/settings/tokens>

- Create a personal Codespace secret
  - <https://github.com/settings/codespaces>
  - Name: PAT
  - Value: the PAT you just created
  - Grant access to this repo and any other repos you want

## Create a Codespace

- Click on `Code` then click `New Codespace`

Once Codespaces is running:

> Make sure your terminal is running zsh - bash is not supported and will not work

## Test Fleet

- Request the Platform Team to create your test fleet
- They will provide the branch name
- Checkout your branch

  ```bash

  cd /workspaces/edge-gitops
  git pull
  git checkout yourBranchName
  git pull

  ```

## Check your Fleet

> flt is the fleet CLI provided by the platform team

```bash

# list clusters in the fleet
flt list

# check heartbeat on the fleet
flt check heartbeat

# update the fleet
# (run twice if there are updates so you can see it's clean)
flt pull

# explore the flt CLI
flt -h

```

> Note that the create, delete, and groups commands will not work unless you're on the core platform team

## Deploy a new app

- AI Order Accuracy is the reference app that has been renamed

```bash

cd apps/ai-order-accuracy

# check deploy targets (should be [])
flt targets list

# add the central region as a target
flt targets add central

# deploy the changes
flt targets deploy

# force flux to sync
# note the github commit ID will change when ci-cd is complete
# you may have to run multiple times
flt sync

# check that ai-order-accuracy is deployed to central
flt check ai-order-accuracy

```

### Engineering Docs

- Team Working [Agreement](.github/WorkingAgreement.md)
- Team [Engineering Practices](.github/EngineeringPractices.md)
- CSE Engineering Fundamentals [Playbook](https://github.com/Microsoft/code-with-engineering-playbook)

## How to file issues and get help

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates. For new issues, file your bug or feature request as a new issue.

For help and questions about using this project, please open a GitHub issue.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services.

Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
